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
        expect(result.screening_result)
          .to be_a(Registration::ScreeningService::Result)
        expect(result.violations).to eq(result.screening_result.violations)
        expect(result.success?).to be(true)
        expect(result.blocker_violations).to be_empty
        expect(result.auto_reject_violations.size).to eq(1)
        expect(result.auto_reject_violations.first[:user_id]).to eq(user.id)
      end
    end

    context "when a closed FCFS campaign has a multi-lecture performance policy" do
      let(:lecture) { create(:lecture) }
      let(:campaign) { create(:registration_campaign, campaignable: lecture) }
      let(:item) { create(:registration_item, registration_campaign: campaign) }
      let(:user) { create(:confirmed_user) }
      let(:passed_lecture) { create(:lecture, :with_organizational_stuff) }
      let(:other_lecture) { create(:lecture, :with_organizational_stuff) }

      before do
        create(:registration_policy, :student_performance,
               registration_campaign: campaign,
               phase: :finalization,
               config: {
                 "lecture_ids" => [other_lecture.id.to_s, passed_lecture.id.to_s]
               })

        campaign.update!(status: :closed)

        create(:registration_user_registration, :confirmed,
               registration_campaign: campaign,
               registration_item: item,
               user: user)
      end

      # Every lecture the policy names has to be passed, so one pass alongside an
      # undecided second is not enough — and the campaign waits for that second.
      it "blocks while one of the selected lectures is still undecided" do
        create(:student_performance_certification, :pending,
               lecture: other_lecture, user: user)
        create(:student_performance_certification, :passed,
               lecture: passed_lecture, user: user)

        result = described_class.new(campaign).check

        expect(result.success?).to be(false)
        expect(result.error_code).to eq(:policy_violation)
      end

      it "does not block once every selected lecture is passed" do
        certifier = create(:confirmed_user)
        [other_lecture, passed_lecture].each do |l|
          create(:student_performance_certification, :passed,
                 lecture: l, user: user, certified_by: certifier)
        end

        result = described_class.new(campaign).check

        expect(result.success?).to be(true)
        expect(result.blocker_violations).to be_empty
      end

      # A lecture that is definitively failed cannot be salvaged by the pending
      # one, so the student is rejected rather than the campaign held up.
      it "rejects rather than blocking when one lecture is failed outright" do
        create(:student_performance_certification, :pending,
               lecture: other_lecture, user: user)
        create(:student_performance_certification, :failed,
               lecture: passed_lecture, user: user)

        result = described_class.new(campaign).check

        expect(result.blocker_violations).to be_empty
        expect(result.auto_reject_violations.size).to eq(1)
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
