module MozillaIAM
  module SerializerExtensions
    module DinoparkProfile

      def self.included(c)
        c.attributes :dinopark_profile
      end

      def dinopark_profile
        profile = API::PersonV2.new.profile(object.custom_fields["mozilla_iam_uid"])
        unless profile.blank?
          profile.to_hash
        end
      end

      def include_dinopark_profile?
        (object&.id == scope.user&.id)
      end

    end
  end
end
