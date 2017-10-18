shared_examples "serialize mozilla_iam custom_fields" do
  let(:user) { Fabricate(:user) }

  describe "#mozilla_iam" do
    context "as an anonymous user" do
      let(:json) { described_class.new(user, scope: Guardian.new, root:false).as_json }

      it "should return nil" do
        user.custom_fields['mozilla_iam_test'] = 'Private data'
        user.save

        expect(json[:mozilla_iam]).to be_nil
      end
    end

    shared_examples "for select users" do
      it "should contain 'mozilla_iam' prefixed custom fields" do
        mozilla_iam_one = 'Some IAM data'
        mozilla_iam_two = 'Some more IAM data'

        user.custom_fields['mozilla_iam_one'] = mozilla_iam_one
        user.custom_fields['mozilla_iam_two'] = mozilla_iam_two
        user.save

        mozilla_iam = json[:mozilla_iam]
        expect(mozilla_iam['one']).to eq(mozilla_iam_one)
        expect(mozilla_iam['two']).to eq(mozilla_iam_two)
      end

      it "shouldn't contain non-'mozilla_iam' prefixed custom fields" do
        user.custom_fields['other_custom_fields'] = 'some data'
        user.save

        expect(json[:mozilla_iam]).to be_empty
      end
    end

    context "as the user themselves" do
      let(:json) { described_class.new(user, scope: Guardian.new(user), root:false).as_json }
      include_examples "for select users"
    end

    context "as a moderator" do
      let(:moderator) { Fabricate(:moderator) }
      let(:json) { described_class.new(user, scope: Guardian.new(moderator), root:false).as_json }
      include_examples "for select users"
    end

    context "as an admin" do
      let(:admin) { Fabricate(:admin) }
      let(:json) { described_class.new(user, scope: Guardian.new(admin), root:false).as_json }
      include_examples "for select users"
    end
  end
end
