require_relative '../../iam_helper'

describe MozillaIAM::Profile do
  let(:user) { Fabricate(:user) }
  let(:profile) { MozillaIAM::Profile.new(user, "uid") }

  context '.refresh' do
    it "refreshes a user who already has a profile" do
      profile
      MozillaIAM::Profile.expects(:new).with(user, "uid").returns(profile)
      MozillaIAM::Profile.any_instance.expects(:refresh).returns(true)
      result = MozillaIAM::Profile.refresh(user)
      expect(result).to be true
    end

    it 'should return nil if user has no profile' do
      result = MozillaIAM::Profile.refresh(user)
      expect(result).to be_nil
    end
  end

  context '#initialize' do
    it "should save a user's uid" do
      profile
      expect(user.custom_fields['mozilla_iam_uid']).to eq("uid")
    end
  end

  context '#refresh' do
    it "returns #force_refresh if #should_refresh? is true" do
      profile.expects(:should_refresh?).returns(true)
      profile.expects(:last_refresh).never
      profile.expects(:force_refresh).once.returns(true)
      expect(profile.refresh).to be true
    end

    it "returns #last_refresh if #should_refresh? is false" do
      profile.expects(:should_refresh?).returns(false)
      profile.expects(:force_refresh).never
      profile.expects(:last_refresh).once.returns(true)
      expect(profile.refresh).to be true
    end

    # it "should refresh a user's profile if it hasn't been refreshed before" do
    #   expect(profile.refresh).to be_within(5.seconds).of Time.now
    # end
  end

  context "#force_refresh" do
    it "calls update_groups" do
      profile.expects(:update_groups)
      profile.force_refresh
    end

    it "sets the last refresh to now and returns it" do
      profile.expects(:set_last_refresh).with() { |t| t.between?(Time.now() - 5, Time.now()) }.returns("time now")
      expect(profile.force_refresh).to eq "time now"
    end
  end


  context "#profile" do
    it "returns a user's profile from the ManagementAPI" do
      MozillaIAM::ManagementAPI.any_instance.expects(:profile).with("uid").returns("profile")
      expect(profile.send(:profile)).to eq "profile"
    end
  end

  context '#update_groups' do
    it 'should remove a user from a mapped group' do
      profile.expects(:profile).returns(groups: [])
      group = Fabricate(:group, users: [user])
      MozillaIAM::GroupMapping.new(iam_group_name: 'iam_group',
                                   authoritative: false,
                                   group: group).save!

      expect(group.users.count).to eq 1

      profile.send(:update_groups)

      expect(group.users.count).to eq 0
    end

    it 'should add a user to a mapped group' do
      profile.expects(:profile).returns(groups: ['iam_group'])
      group = Fabricate(:group)
      MozillaIAM::GroupMapping.new(iam_group_name: 'iam_group',
                                   authoritative: false,
                                   group: group).save!

      expect(group.users.count).to eq 0

      profile.send(:update_groups)

      expect(group.users.count).to eq 1
    end
  end
end
