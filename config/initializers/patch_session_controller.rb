if !Rails.env.production?
  module MozillaIAM
    module SessionControllerBecomeExtensions
      def become
        session[:mozilla_iam] = {
          last_refresh: Time.now,
          aal: "MAXIMUM"
        }
        super
      end
    end
  end

  SessionController.prepend MozillaIAM::SessionControllerBecomeExtensions
end

if Rails.env.test?
  require_relative '../../../../spec/support/integration_helpers'

  module MozillaIAM
    module IntegrationHelpersExtensions
      def sign_in(user)
        user = super
        MozillaIAM::Profile.stubs(:refresh_methods).returns([])
        user.custom_fields['mozilla_iam_uid'] = "ad|Mozilla-LDAP|#{user.username}"
        user.custom_fields['mozilla_iam_last_refresh'] = Time.now
        user.save_custom_fields
        user
      end
    end
  end

  IntegrationHelpers.prepend MozillaIAM::IntegrationHelpersExtensions
end
