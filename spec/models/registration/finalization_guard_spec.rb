require "rails_helper"

RSpec.describe(Registration::FinalizationGuard, type: :model) do
  let(:campaign) do
    build(:registration_campaign,
          :preference_based,
          status: :processing,
          allocation_decided_at: Time.current)
  end
  let(:guard) { described_class.new(campaign) }

  describe "#check" do
    context "when campaign is processing" do
      it "returns success" do
        result = guard.check
        expect(result.success?).to be(true)
      end
    end

    context "when preference campaign has no decided allocation" do
      let(:campaign) do
        build(:registration_campaign, :preference_based, status: :processing)
      end

      it "returns failure" do
        result = guard.check
        expect(result.success?).to be(false)
        expect(result.error_code).to eq(:wrong_status)
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

    context "when a closed FCFS campaign has auto-reject violations" do
      let(:lecture) { create(:lecture) }
      let(:campaign) do
        create(:registration_campaign, campaignable: lecture)
      end
      let(:item) do
        create(:registration_item, registration_campaign: campaign)
      end
      let(:user) { create(:confirmed_user, email: "invalid@other.com") }

      before do
        create(:registration_policy, :institutional_email,
               registration_campaign: campaign,
               phase: :finalization,
               config: { "allowed_domains" => "uni.edu" })

        campaign.update!(status: :closed)

        create(:registration_user_registration,
               registration_campaign: campaign,
               registration_item: item,
               user: user)
      end

      it "returns success and exposes projected auto rejections" do
        result = described_class.new(campaign).check

        expect(result.success?).to be(true)
        expect(result.blocker_violations).to be_empty
        expect(result.auto_reject_violations.size).to eq(1)
        expect(result.auto_reject_violations.first[:user_id]).to eq(user.id)
      end
    end

    context "with policies" do
      # Create as draft first to allow policy creation
      let(:campaign) do
        create(:registration_campaign, :preference_based, :with_items, status: :draft)
      end
      let(:item) { campaign.registration_items.first }
      let(:user) { create(:user, email: "valid@uni.edu") }

      before do
        create(:registration_policy, :institutional_email,
               registration_campaign: campaign,
               phase: :finalization,
               config: { "allowed_domains" => "uni.edu" })

        # Now move to processing
        campaign.update!(status: :processing,
                         allocation_decided_at: Time.current)

        create(:registration_user_registration, :confirmed,
               registration_campaign: campaign,
               registration_item: item,
               user: user)
      end

      it "passes if all confirmed users satisfy policies" do
        result = guard.check
        expect(result.success?).to be(true)
      end

      it "does not reevaluate policy failures after allocation was decided" do
        invalid_user = create(:confirmed_user, email: "invalid@other.com")
        create(:registration_user_registration, :confirmed,
               registration_campaign: campaign,
               registration_item: item,
               user: invalid_user)

        result = guard.check
        expect(result.success?).to be(true)
      end

      it "does not reevaluate users who become invalid after allocation was decided" do
        expect(guard.check.success?).to be(true)

        user.skip_reconfirmation!
        user.update(email: "invalid@other.com")

        result = guard.check
        expect(result.success?).to be(true)
      end

      it "ignores unconfirmed users" do
        other_user = create(:user, email: "invalid@other.com")
        create(:registration_user_registration, :pending,
               registration_campaign: campaign,
               registration_item: item,
               preference_rank: 1,
               user: other_user)

        result = guard.check
        expect(result.success?).to be(true)
      end
    end
  end
end
