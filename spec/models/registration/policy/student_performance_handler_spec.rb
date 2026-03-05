require "rails_helper"

RSpec.describe(Registration::Policy::StudentPerformanceHandler, type: :model) do
  let(:lecture) { create(:lecture, :with_organizational_stuff) }
  let(:policy) do
    build(:registration_policy, :student_performance,
          config: { "lecture_id" => lecture.id })
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

    it "fails if user has a failed certification" do
      create(:student_performance_certification, :failed,
             lecture: lecture,
             user: user,
             certified_by: create(:confirmed_user))
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:certification_not_passed)
      expect(result[:details][:certification_status]).to eq(:failed)
    end

    it "fails if user has a pending certification" do
      create(:student_performance_certification, :pending,
             lecture: lecture,
             user: user)
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:certification_not_passed)
      expect(result[:details][:certification_status]).to eq(:pending)
    end

    it "fails with :missing if user has no certification" do
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:certification_not_passed)
      expect(result[:details][:certification_status]).to eq(:missing)
    end

    it "fails with configuration error if lecture is missing" do
      policy.config = {}
      result = handler.evaluate(user)
      expect(result[:pass]).to be(false)
      expect(result[:code]).to eq(:configuration_error)
    end
  end

  describe "#validate" do
    it "adds error if lecture_id is missing" do
      policy.config = {}
      handler.validate
      expect(policy.errors[:lecture_id])
        .to include(I18n.t("registration.policy.errors.missing_lecture"))
    end

    it "adds error if lecture does not exist" do
      policy.config["lecture_id"] = 99_999
      handler.validate
      expect(policy.errors[:lecture_id])
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

    it "returns nil if lecture does not exist" do
      policy.config["lecture_id"] = 99_999
      expect(handler.summary).to be_nil
    end
  end
end
