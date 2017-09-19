require_relative '../../iam_helper'

describe MozillaIAM::Profile do
  context '.refresh' do
    it 'should return nil if user has no profile' do
      user = Fabricate(:user)
      result = MozillaIAM::Profile.refresh(user)
      expect(result).to be_nil
    end
  end

  context '#initialize' do
    let(:user) { Fabricate(:user) }
    let(:uid) { create_uid(user.username) }
    it "should save a user's uid" do
      MozillaIAM::Profile.new(user, uid)

      expect(user.custom_fields['mozilla_iam_uid']).to eq(uid)
    end

    it "should save any login_data provided" do
      extra_login_data = 'this is really important'
      MozillaIAM::Profile.new(user, uid, extra_login_data: extra_login_data)

      expect(user.custom_fields['mozilla_iam_extra_login_data']).to eq(extra_login_data)
    end

    it "should survive if login_data is nil" do
      login_data = nil
      MozillaIAM::Profile.new(user, uid, login_data)

      expect(user.custom_fields['mozilla_iam_uid']).to eq(uid)
    end
  end

  context '#refresh' do
    it "should refresh a user's profile if it hasn't been refreshed before" do
      user = Fabricate(:user)
      uid = create_uid(user.username)

      result = MozillaIAM::Profile.new(user, uid).refresh

      expect(result).to be_within(5.seconds).of Time.now
    end
  end

  context '#update_groups' do
    it 'should remove a user from a mapped group' do
      user = Fabricate(:user)
      uid = create_uid(user.username)
      group = Fabricate(:group, users: [user])
      MozillaIAM::GroupMapping.new(iam_group_name: 'iam_group',
                                   authoritative: false,
                                   group: group).save!

      expect(group.users.count).to eq 1

      stub_api_users_request(uid, groups: [])

      MozillaIAM::Profile.new(user, uid).refresh
      expect(group.users.count).to eq 0
    end

    it 'should add a user to a mapped group' do
      user = Fabricate(:user)
      uid = create_uid(user.username)
      group = Fabricate(:group)
      MozillaIAM::GroupMapping.new(iam_group_name: 'iam_group',
                                   authoritative: false,
                                   group: group).save!

      expect(group.users.count).to eq 0

      stub_api_users_request(uid, groups: ['iam_group'])

      MozillaIAM::Profile.new(user, uid).refresh
      expect(group.users.count).to eq 1
    end
  end
end
