require_relative '../iam_helper'
require_dependency 'email_updater'

def login(identity)
  OmniAuth.config.mock_auth[:auth0] = OmniAuth::AuthHash.new(
    provider: 'auth0',
    credentials: OmniAuth::AuthHash.new(
     id_token: create_id_token(identity)
    )
  )

  Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:auth0]

  get "/auth/auth0/callback.json"
  JSON.parse(flash[:authentication_data])
end

describe Users::OmniauthCallbacksController do
  before do
    OmniAuth.config.test_mode = true
  end

  after do
    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:auth0] = nil
    OmniAuth.config.test_mode = false
  end

  context 'changing email' do
    it 'works as unexpected' do
      stub_jwks_request
      old_email = 'old@email.com'
      old_identity = { name: 'Bob',
                       username: 'bob',
                       email: old_email }
      user = Fabricate(:user, email: old_email)
      new_email = 'new@email.com'
      new_identity = { name: 'Bob',
                       username: 'boguslaw',
                       email: new_email }

      response = login(old_identity)
      expect(response['authenticated']).to eq(true)

      updater = EmailUpdater.new(user.guardian, user)
      updater.change_to(new_email)

      # response = login(new_identity)
      # expect(response['authenticated']).to eq(nil)
      # expect(response['email']).to eq(new_email)
      # we could repeat the above 3 lines infinitely
      # and the test would continue to pass

      user.reload
      expect(user.email).to eq(old_email)

      response = login(old_identity)
      expect(response['authenticated']).to eq(true)

      user.reload
      expect(user.email).to eq(new_email)

      response = login(new_identity)
      expect(response['authenticated']).to eq(true)

      response = login(old_identity)
      expect(response['authenticated']).to eq(nil)
      expect(response['email']).to eq(old_email)
    end
  end
end
