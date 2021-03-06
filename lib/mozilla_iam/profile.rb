module MozillaIAM
  class Profile
    attr_reader :uid
    attr_reader :user
    @refresh_methods = []
    @array_keys = []

    class << self
      attr_accessor :refresh_methods
      attr_accessor :array_keys

      def during_refresh(method_name)
        refresh_methods << method_name
      end

      def register_as_array(key)
        array_keys << key
      end

      def for(user)
        uid = get(user, :uid)
        return if uid.blank?
        Profile.new(user, uid)
      end

      def refresh(user)
        profile = self.for(user)
        profile.refresh unless profile.nil?
      end

      def find_by_uid(uid)
        user = UserCustomField.where(name: "mozilla_iam_uid", value: uid).last&.user
        return if user.nil?
        return Profile.new(user, uid)
      end

      def find_or_create_user_from_uid_and_secondary_emails(uid)
        # This shouldn't be used to give users access from their uid,
        # as it'll associate on secondary emails, meaning a staff
        # account could be returned despite the uid coming from
        # an insecure 1FA method of authentication

        user = find_by_uid(uid)&.user
        return user if user

        email = API::Management.new.profile(uid).email
        raise "#{uid} doesn't exist" if email.blank?
        user = User.find_by_email(email)
        raise EmailExistsError.new(email, user) if user

        user = User.create!(
          email: email,
          username: UserNameSuggester.suggest(email),
          name: User.suggest_name(email),
          staged: true
        )

        Profile.new(user, uid)
        user
      end
    end

    def initialize(user, uid)
      @user = user
      @uid = set(:uid, uid)
      @api_profiles = {}
    end

    def refresh
      return last_refresh unless should_refresh?
      force_refresh
    end

    def force_refresh
      DistributedMutex.synchronize("mozilla_iam_refresh_#{@user.id}") do
        @api_profiles = {}
        self.class.refresh_methods.each { |name| self.send(name) }
        set_last_refresh(Time.now)
      end
    end

    def attr(attr)
      apis = API.profile_apis.select { |api| api::Profile.method_defined? attr }
      response = nil
      apis.each do |api|
        @api_profiles[api.name] ||= api.profile(@uid)
        value = @api_profiles[api.name].send(attr)
        if response.nil?
          response = value
        elsif [response, value].map { |x| x.kind_of? Array }.all?
          response = response | value
        end
      end
      return response
    end

    def last_refresh
      @last_refresh ||=
        if time = get(:last_refresh)
          Time.parse(time)
        end
    end

    def reload
      @user.clear_custom_fields
      @last_refresh = nil
    end

    private

    def set_last_refresh(time)
      @last_refresh = set(:last_refresh, time)
    end

    def should_refresh?
      return true unless last_refresh
      Time.now > last_refresh + 900
    end

    def self.get(user, key)
      user.custom_fields["mozilla_iam_#{key}"]
    end

    def get(key)
      self.class.get(@user, key)
    end

    def self.set(user, key, value)
      user.upsert_custom_fields([["mozilla_iam_#{key}", value]])
      user.save_custom_fields
      value
    end

    def set(key, value)
      self.class.set(@user, key, value)
    end

    class EmailExistsError < StandardError
      attr_reader :user

      def initialize(email, user)
        @user = user
        super "attempted to create staged user with email #{email}, but a user with that email already exists"
      end
    end

  end
end

require_relative "profile/update_groups"
require_relative "profile/update_emails"
require_relative "profile/duplicate_accounts"
require_relative "profile/is_aal_enough"
require_relative "profile/dinopark_enabled"
require_relative "profile/update_avatar"
require_relative "profile/update_bio"
require_relative "profile/update_location"
require_relative "profile/update_name"
require_relative "profile/update_title"
require_relative "profile/update_username"
require_relative "profile/update_website"
