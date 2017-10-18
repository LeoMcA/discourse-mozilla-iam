require_relative '../../iam_helper'

describe MozillaIAM::Authenticator do
  context '#after_authenticate' do
    it 'can authenticate a new user' do
      user = {
        name: 'John Doe',
        email: 'jdoe@mozilla.com',
        username: 'jdoe'
      }
      result = authenticate_user(user)

      expect(result.user).to             eq(nil)
      expect(result.email).to            eq(user[:email])
      expect(result.email_valid).to      eq(true)
      expect(result.name).to             eq(user[:name])
      expect(result.extra_data[:uid]).to eq("ad|Mozilla-LDAP|#{user[:username]}")
    end

    it 'can authenticate and create a profile for an existing user' do
      user = Fabricate(:user)
      result = authenticate_user(user)

      uid = user.custom_fields['mozilla_iam_uid']
      last_refresh = Time.parse(user.custom_fields['mozilla_iam_last_refresh'])

      expect(result.user.id).to          eq(user.id)
      expect(result.email).to            eq(user.email)
      expect(result.email_valid).to      eq(true)
      expect(result.name).to             eq(user.name)
      expect(result.extra_data[:uid]).to eq(create_uid(user.username))
      expect(uid).to                     eq(create_uid(user.username))
      expect(last_refresh).to            be_within(5.seconds).of Time.now
    end

    it 'can refresh an existing profile for an existing user' do
      user = Fabricate(:user)
      user.custom_fields['mozilla_iam_uid'] = create_uid(user.username)
      user.custom_fields['mozilla_iam_last_refresh'] = Time.now - 14.minutes
      user.save_custom_fields

      uid = user.custom_fields['mozilla_iam_uid']
      last_refresh = Time.parse(user.custom_fields['mozilla_iam_last_refresh'])

      expect(uid).to                     eq(create_uid(user.username))
      expect(last_refresh).to            be_within(5.seconds).of Time.now - 14.minutes

      result = authenticate_user(user)

      user.clear_custom_fields
      uid = user.custom_fields['mozilla_iam_uid']
      last_refresh = Time.parse(user.custom_fields['mozilla_iam_last_refresh'])

      expect(result.user.id).to          eq(user.id)
      expect(result.email).to            eq(user.email)
      expect(result.email_valid).to      eq(true)
      expect(result.name).to             eq(user.name)
      expect(result.extra_data[:uid]).to eq(create_uid(user.username))
      expect(uid).to                     eq(create_uid(user.username))
      expect(last_refresh).to            be_within(5.seconds).of Time.now
    end

    it 'can refresh an existing profile for an existing user with a new uid' do
      user = Fabricate(:user)
      old_uid = "the_best_uid"
      new_uid = create_uid(user.username)
      user.custom_fields['mozilla_iam_uid'] = old_uid
      user.custom_fields['mozilla_iam_last_refresh'] = Time.now - 14.minutes
      user.save_custom_fields

      uid = user.custom_fields['mozilla_iam_uid']
      last_refresh = Time.parse(user.custom_fields['mozilla_iam_last_refresh'])

      expect(uid).to                     eq(old_uid)
      expect(last_refresh).to            be_within(5.seconds).of Time.now - 14.minutes

      result = authenticate_user(user)

      user.clear_custom_fields
      uid = user.custom_fields['mozilla_iam_uid']
      last_refresh = Time.parse(user.custom_fields['mozilla_iam_last_refresh'])

      expect(result.user.id).to          eq(user.id)
      expect(result.email).to            eq(user.email)
      expect(result.email_valid).to      eq(true)
      expect(result.name).to             eq(user.name)
      expect(result.extra_data[:uid]).to eq(new_uid)
      expect(uid).to                     eq(new_uid)
      expect(last_refresh).to            be_within(5.seconds).of Time.now
    end

    it 'will not log in with an invalid id_token' do
      result = authenticate_with_id_token('really_invalid')

      expect(result.failed).to eq(true)
    end

    it 'will not log in with an expired id_token' do
      user = Fabricate(:user)
      id_token = create_id_token(user, { exp: Time.now, iat: Time.now - 7.days })
      result = authenticate_with_id_token(id_token)

      expect(result.failed).to eq(true)
    end

    it 'will not log in with an id_token with an unverified email' do
      user = Fabricate(:user)
      id_token = create_id_token(user, { email_verified: false })
      result = authenticate_with_id_token(id_token)

      expect(result.user).to eq(nil)
    end

    context "mozillians primary email" do
      it "doesn't exist, so doesn't store it" do
        user = Fabricate(:user)
        result = authenticate_user(user)

        expect(
          user.custom_fields['mozilla_iam_mozillians_primary_email']
        ).to eq(nil)
      end

      it "exists, so stores it" do
        user = Fabricate(:user)
        mozillians_primary_email = 'lmcardle@mozilla.com'
        mozillians_profile = { 'email' => { 'value' => mozillians_primary_email } }
        result = authenticate_user(user, mozillians_profile)

        expect(
          user.custom_fields['mozilla_iam_mozillians_primary_email']
        ).to eq(mozillians_primary_email)
      end
    end
  end

  context '#after_create_account' do
    it 'can create profile for new user' do
      user = Fabricate(:user)
      auth = { extra_data: { uid: create_uid(user.username) }}

      authenticator = MozillaIAM::Authenticator.new('auth0', trusted: true)
      result = authenticator.after_create_account(user, auth)

      uid = user.custom_fields['mozilla_iam_uid']
      last_refresh = Time.parse(user.custom_fields['mozilla_iam_last_refresh'])

      expect(result).to       be_within(5.seconds).of Time.now
      expect(last_refresh).to be_within(5.seconds).of Time.now
      expect(uid).to          eq(create_uid(user.username))
    end
  end
end
