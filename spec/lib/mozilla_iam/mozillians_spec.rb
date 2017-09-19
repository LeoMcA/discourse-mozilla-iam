require_relative '../../iam_helper'

describe MozillaIAM::Mozillians::User do
  context '.new' do
    it 'gets the api key from SiteSettings' do
      key = '123'
      SiteSetting.mozillians_api_key = key
      expect(
        described_class.new().instance_variable_get(:@api_key)
      ).to eq(key)
    end
  end

  context '#find_by_email' do
    let(:email) { 'lmcardle@mozilla.com' }
    it 'returns false if api key is invalid' do
      SiteSetting.mozillians_api_key = 'invalid'
      stub_mozillians_users_request(email: email, invalid_key: true)
      expect(
        described_class.new().find_by_email(email)
      ).to eq(false)
    end

    it 'returns false if the user doesn\'t exist' do
      stub_mozillians_users_request(email: email, no_user: true)
      expect(
        described_class.new().find_by_email(email)
      ).to eq(false)
    end

    it 'returns a profile if the user exists' do
      stub_mozillians_users_request(email: email)
      expect(
        described_class.new().find_by_email(email)['email']['value']
      ).to eq(email)
    end
  end
end
