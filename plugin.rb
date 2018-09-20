# name: mozilla-iam
# about: A plugin to integrate Discourse with Mozilla's Identity and Access Management (IAM) system
# version: 0.2.10
# authors: Leo McArdle
# url: https://github.com/mozilla/discourse-mozilla-iam

gem 'omniauth-auth0', '2.0.0'

require 'jwt'
require 'faraday'
require 'multi_json'
require 'base64'
require 'openssl'

require 'auth/oauth2_authenticator'

require_relative 'lib/mozilla_iam'

add_admin_route 'mozilla_iam.mappings.title', 'mozilla-iam.mappings'

register_asset "stylesheets/common/mozilla-iam.scss"

auth_provider(title: 'Mozilla',
              message: 'Log In / Sign Up',
              authenticator: MozillaIAM::Authenticator.new('auth0', trusted: true),
              full_screen_login: true)

after_initialize do
  Users::OmniauthCallbacksController.view_paths = ["plugins/discourse-mozilla-iam/app/views", "app/views"]
  Users::OmniauthCallbacksController.class_eval do
    def failure
      flash[:error] = I18n.t("login.omniauth_error_unknown")
      render 'failure'
    end
  end
end
