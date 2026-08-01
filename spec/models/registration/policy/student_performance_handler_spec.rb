require "rails_helper"

RSpec.describe(Registration::Policy::StudentPerformanceHandler, type: :model) do
  let(:lecture) { create(:lecture, :with_organizational_stuff) }
  let(:other_lecture) { create(:lecture, :with_organizational_stuff) }
  let(:policy) do
    build(:registration_policy, :student_performance,
          config: { "lecture_ids" => [lecture.id.to_s] })
  end
  let(:handler) { described_class.new(policy) }
  let(:user) { create(:confirmed_user) }

  describe "#evaluate" do
    it "passes if user has a passed certification" do
      create(:student_performance_certification, :passed,
             lecture: lecture,
             user: user,
             certified_by: create(:confirmed_user))
      result = handler.evaluate(user)
      expect(result[:pass]).to be(true)
      expect(result[:code]).to eq(:certification_passed)
    end

    # Every configured lecture counts. A pass in one of them says nothing about
    # the other, so it cannot stand in for it.
    it "fails if only one of several selected lectures is passed" do
      policy.config["lecture_ids"] = [lecture.id.to_s, other_lecture.id.to_s]

      create(:student_performance_certification, :passed,
             lecture: other_lecture,
             user: user,
             certified_by: create(:confirmed_user))

      result = handler.evaluate(user)

      expect(result[:pass]).to be(false)
      expect(result[:details][:certification_status]).to eq(:missing)
      expect(result[:details][:outstanding_lectures]).to eq([lecture.title])
    end

    it "passes once every selected lecture is passed" do
      policy.config["lecture_ids"] = [lecture.id.to_s, other_lecture.id.to_s]
      certifier = create(:confirmed_user)

      [lecture, other_lecture].each do |l|
        create(:student_performance_certification, :passed,
               lecture: l, user: user, certified_by: certifier)
      end

      result = handler.evaluate(user)

      expect(result[:pass]).to be(true)
      expect(result[:code]).to eq(:certification_passed)
    end

    # One lecture cannot be passed any more, so the case is settled rather than
    # merely open — which is what turns a blocker into an auto-reject.
    it "reports a definitive failure even when another lecture is only pending" do
      policy.config["lecture_ids"] = [lecture.id.to_s, other_lecture.id.to_s]

      create(:student_performance_certification, :failed,
             lecture: lecture, user: user, certified_by: create(:confirmed_user))
      create(:student_performance_certification,
             lecture: other_lecture, user: user, status: :pending)

      result = handler.evaluate(user)

      expect(result[:pass]).to be(false)
      expect(result[:details][:certification_status]).to eq(:failed)
      expect(result[:classification])
        .to eq(Registration::ScreeningService::CLASSIFICATION_AUTO_REJECT)
    end

    it "fails if user has a failed certification" do
      create(:student_performance_certification, :failed,
             lecture: lecture,
             user: user,
             certified_by: create(:confirmed_user))
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:certification_not_passed)
      expect(result[:details][:certification_status]).to eq(:failed)
      expect(result[:classification])
        .to eq(Registration::ScreeningService::CLASSIFICATION_AUTO_REJECT)
      expect(result[:reason_type])
        .to eq(Registration::UserRegistration::REJECTION_REASON_TYPE_POLICY)
      expect(result[:reason_code]).to eq(:certification_not_passed)
    end

    it "fails if user has a pending certification" do
      create(:student_performance_certification, :pending,
             lecture: lecture,
             user: user)
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:certification_not_passed)
      expect(result[:details][:certification_status]).to eq(:pending)
      expect(result[:classification])
        .to eq(Registration::ScreeningService::CLASSIFICATION_BLOCKER)
    end

    it "fails with :missing if user has no certification" do
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:certification_not_passed)
      expect(result[:details][:certification_status]).to eq(:missing)
      expect(result[:classification])
        .to eq(Registration::ScreeningService::CLASSIFICATION_BLOCKER)
    end

    it "fails with configuration error if lecture_id is blank" do
      policy.config = {}
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:configuration_error)
      expect(result[:classification])
        .to eq(Registration::ScreeningService::CLASSIFICATION_BLOCKER)
      expect(result[:blocker_kind])
        .to eq(Registration::ScreeningService::BLOCKER_KIND_CONFIGURATION)
    end

    it "fails with lecture_not_found if lecture was deleted" do
      policy.config = { "lecture_ids" => ["99999"] }
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:lecture_not_found)
      expect(result[:classification])
        .to eq(Registration::ScreeningService::CLASSIFICATION_BLOCKER)
      expect(result[:blocker_kind])
        .to eq(Registration::ScreeningService::BLOCKER_KIND_CONFIGURATION)
    end
  end

  describe "#validate" do
    it "adds error if lecture_id is missing" do
      policy.config = {}
      handler.validate
      expect(policy.errors[:lecture_ids])
        .to include(I18n.t("registration.policy.errors.missing_lecture"))
    end

    it "adds error if lecture does not exist" do
      policy.config["lecture_ids"] = ["99999"]
      handler.validate
      expect(policy.errors[:lecture_ids])
        .to include(I18n.t("registration.policy.errors.lecture_not_found"))
    end

    it "does not add errors for a valid lecture" do
      handler.validate
      expect(policy.errors).to be_empty
    end
  end

  describe "#summary" do
    it "returns lecture title" do
      expect(handler.summary).to eq(lecture.title)
    end

    it "returns all selected lecture titles" do
      policy.config["lecture_ids"] = [lecture.id.to_s, other_lecture.id.to_s]

      expect(handler.summary).to eq([lecture.title, other_lecture.title].join(", "))
    end

    it "returns nil if lecture does not exist" do
      policy.config["lecture_ids"] = ["99999"]
      expect(handler.summary).to be_nil
    end
  end
end
