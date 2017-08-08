require_relative '../../iam_helper'

describe MozillaIAM::Profiles do
  context '.refresh' do

    let :user1 { Fabricate(:user) }
    let :uid1 { create_uid(user1.username) }

    let :user2 { Fabricate(:user) }
    let :uid2 { create_uid(user2.username) }

    let :users { [user1, user2] }
    let :uids { [uid1, uid2] }

    before do
      MozillaIAM::Profile.new(user1, uid1)
      MozillaIAM::Profile.new(user2, uid2)
    end

    it "shouldn't return a user's uid if they have no profile" do
      user3 = Fabricate(:user)

      stub_api_user(uid1)
      stub_api_user(uid2)
      stub_api_users_search(uids)
      result = MozillaIAM::Profiles.refresh([user1, user2, user3])
      expect(result).to eq(uids)
    end

    it "should refresh multiple users' profiles" do
      stub_api_user(uid1)
      stub_api_user(uid2)
      stub_api_users_search(uids)
      MozillaIAM::Profiles.refresh(users)

      users.map! do |user|
        user.clear_custom_fields
        Time.parse(user.custom_fields['mozilla_iam_last_refresh'])
      end

      expect(users[0]).to be_within(5.seconds).of Time.now
      expect(users[1]).to be_within(5.seconds).of Time.now
    end

    it 'should remove a user from a mapped group' do
      group = Fabricate(:group, users: users)
      MozillaIAM::GroupMapping.new(iam_group_name: 'iam_group',
                                   authoritative: false,
                                   group: group).save!

      expect(group.users.count).to eq 2

      stub_api_user(uid1, groups: ['iam_group'])
      stub_api_user(uid2, groups: [])
      stub_api_users_search(uids)

      MozillaIAM::Profiles.refresh(users)
      expect(group.users.count).to eq 1
      expect(group.users.first).to eq user1
    end

    it 'should add a user to a mapped group' do
      group = Fabricate(:group, users: [user1])
      MozillaIAM::GroupMapping.new(iam_group_name: 'iam_group',
                                   authoritative: false,
                                   group: group).save!

      expect(group.users.count).to eq 1

      stub_api_user(uid1, groups: ['iam_group'])
      stub_api_user(uid2, groups: ['iam_group'])
      stub_api_users_search(uids)

      MozillaIAM::Profiles.refresh(users)
      group.users.reload

      expect(group.users.count).to eq(2)
      expect(group.users.second).to eq user2
    end
  end
end
