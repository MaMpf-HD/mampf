require "rails_helper"

RSpec.describe(Registration::FinalizationGuard, type: :model) do
  let(:campaign) { build(:registration_campaign, status: :processing) }
  let(:guard) { described_class.new(campaign) }

  describe "#check" do
    context "when campaign is processing" do
      it "returns success" do
        result = guard.check
        expect(result.success?).to be(true)
      end
    end

    context "when campaign is completed" do
      let(:campaign) { build(:registration_campaign, status: :completed) }

      it "returns failure" do
        result = guard.check
        expect(result.success?).to be(false)
        expect(result.error_code).to eq(:already_completed)
      end
    end

    context "when campaign is open" do
      let(:campaign) { build(:registration_campaign, status: :open) }

      it "returns failure" do
        result = guard.check
        expect(result.success?).to be(false)
        expect(result.error_code).to eq(:wrong_status)
      end
    end

    context "when campaign is closed" do
      let(:campaign) { build(:registration_campaign, status: :closed) }

      it "returns success" do
        result = guard.check
        expect(result.success?).to be(true)
      end
    end

    context "with policies" do
      # Create as draft first to allow policy creation
      let(:campaign) { create(:registration_campaign, :with_items, status: :draft) }
      let(:item) { campaign.registration_items.first }
      let(:user) { create(:user, email: "valid@uni.edu") }

      before do
        create(:registration_policy, :institutional_email,
               registration_campaign: campaign,
               phase: :finalization,
               config: { "allowed_domains" => "uni.edu" })

        # Now move to processing
        campaign.update!(status: :processing)

        create(:registration_user_registration, :confirmed,
               registration_campaign: campaign,
               registration_item: item,
               user: user)
      end

      it "passes if all confirmed users satisfy policies" do
        result = guard.check
        expect(result.success?).to be(true)
      end

      it "fails if a confirmed user violates policy" do
        invalid_user = create(:confirmed_user, email: "invalid@other.com")
        create(:registration_user_registration, :confirmed,
               registration_campaign: campaign,
               registration_item: item,
               user: invalid_user)

        result = guard.check
        expect(result.success?).to be(false)
        expect(result.error_code).to eq(:policy_violation)
        expect(result.data).to include(hash_including(user_id: invalid_user.id,
                                                      policy: "institutional_email"))
      end

      it "fails if a user becomes invalid after registration" do
        # User starts valid (from let(:user))
        expect(guard.check.success?).to be(true)

        # User changes email to invalid
        # We need to skip reconfirmation to ensure the email is updated immediately
        # without waiting for the user to click a confirmation link
        user.skip_reconfirmation!
        user.update(email: "invalid@other.com")

        result = guard.check
        expect(result.success?).to be(false)
        expect(result.error_code).to eq(:policy_violation)
        expect(result.data).to include(hash_including(user_id: user.id,
                                                      policy: "institutional_email"))
      end

      it "ignores unconfirmed users" do
        other_user = create(:user, email: "invalid@other.com")
        create(:registration_user_registration, :pending,
               registration_campaign: campaign,
               registration_item: item,
               user: other_user)

        result = guard.check
        expect(result.success?).to be(true)
      end
    end
  end
end
