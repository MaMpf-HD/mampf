require "rails_helper"

RSpec.describe(StudentPerformance::Certification, type: :model) do
  describe "factory" do
    it "creates a valid pending certification" do
      cert = FactoryBot.create(:student_performance_certification)
      expect(cert).to be_valid
      expect(cert).to be_pending
      expect(cert).to be_computed
    end

    it "creates a valid passed certification" do
      cert = FactoryBot.create(:student_performance_certification, :passed)
      expect(cert).to be_valid
      expect(cert).to be_passed
      expect(cert.certified_by).to be_present
      expect(cert.certified_at).to be_present
    end

    it "creates a valid failed certification" do
      cert = FactoryBot.create(:student_performance_certification, :failed)
      expect(cert).to be_valid
      expect(cert).to be_failed
    end

    it "creates a valid manual certification" do
      cert = FactoryBot.create(:student_performance_certification,
                               :passed, :manual)
      expect(cert).to be_valid
      expect(cert).to be_manual
    end
  end

  describe "associations" do
    it "belongs to a lecture" do
      cert = FactoryBot.build(:student_performance_certification,
                              lecture: nil)
      expect(cert).not_to be_valid
    end

    it "belongs to a user" do
      cert = FactoryBot.build(:student_performance_certification,
                              user: nil)
      expect(cert).not_to be_valid
    end

    it "optionally belongs to certified_by" do
      cert = FactoryBot.build(:student_performance_certification,
                              certified_by: nil)
      expect(cert).to be_valid
    end

    it "optionally belongs to a rule" do
      cert = FactoryBot.build(:student_performance_certification,
                              rule: nil)
      expect(cert).to be_valid
    end
  end

  describe "validations" do
    it "enforces uniqueness of lecture/user pair" do
      cert = FactoryBot.create(:student_performance_certification)
      duplicate = FactoryBot.build(:student_performance_certification,
                                   lecture: cert.lecture,
                                   user: cert.user)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:lecture_id]).to be_present
    end

    it "requires certified_by when passed" do
      cert = FactoryBot.build(:student_performance_certification,
                              status: :passed,
                              certified_by: nil,
                              certified_at: Time.current)
      expect(cert).not_to be_valid
      expect(cert.errors[:certified_by]).to be_present
    end

    it "requires certified_at when passed" do
      certifier = FactoryBot.create(:confirmed_user)
      cert = FactoryBot.build(:student_performance_certification,
                              status: :passed,
                              certified_by: certifier,
                              certified_at: nil)
      expect(cert).not_to be_valid
      expect(cert.errors[:certified_at]).to be_present
    end

    it "does not require certified_by when pending" do
      cert = FactoryBot.build(:student_performance_certification,
                              status: :pending,
                              certified_by: nil,
                              certified_at: nil)
      expect(cert).to be_valid
    end

    it "requires certified_by when failed" do
      cert = FactoryBot.build(:student_performance_certification,
                              status: :failed,
                              certified_by: nil,
                              certified_at: Time.current)
      expect(cert).not_to be_valid
    end
  end

  describe "enums" do
    it "defines status enum" do
      expect(described_class.statuses).to eq(
        "pending" => 0, "passed" => 1, "failed" => 2
      )
    end

    it "defines source enum" do
      expect(described_class.sources).to eq(
        "computed" => 0, "manual" => 1
      )
    end
  end

  describe ".passed?" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:user) { FactoryBot.create(:confirmed_user) }

    it "returns true when certification is passed" do
      FactoryBot.create(:student_performance_certification,
                        :passed,
                        lecture: lecture,
                        user: user)
      expect(described_class.passed?(lecture: lecture, user: user))
        .to be(true)
    end

    it "returns false when certification is pending" do
      FactoryBot.create(:student_performance_certification,
                        lecture: lecture,
                        user: user)
      expect(described_class.passed?(lecture: lecture, user: user))
        .to be(false)
    end

    it "returns false when no certification exists" do
      expect(described_class.passed?(lecture: lecture, user: user))
        .to be(false)
    end
  end

  describe ".stale" do
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:user) { FactoryBot.create(:confirmed_user) }
    let(:certifier) { FactoryBot.create(:confirmed_user) }

    it "includes certifications where record was computed after certification" do
      FactoryBot.create(:student_performance_record,
                        lecture: lecture, user: user,
                        computed_at: 1.hour.ago)
      cert = FactoryBot.create(:student_performance_certification, :passed,
                               lecture: lecture, user: user,
                               certified_by: certifier,
                               certified_at: 2.hours.ago)

      expect(described_class.stale).to include(cert)
    end

    it "excludes certifications where record was computed before certification" do
      FactoryBot.create(:student_performance_record,
                        lecture: lecture, user: user,
                        computed_at: 2.hours.ago)
      cert = FactoryBot.create(:student_performance_certification, :passed,
                               lecture: lecture, user: user,
                               certified_by: certifier,
                               certified_at: 1.hour.ago)

      expect(described_class.stale).not_to include(cert)
    end

    it "excludes pending certifications without certified_at" do
      FactoryBot.create(:student_performance_record,
                        lecture: lecture, user: user,
                        computed_at: 1.hour.ago)
      cert = FactoryBot.create(:student_performance_certification,
                               lecture: lecture, user: user)

      expect(described_class.stale).not_to include(cert)
    end
  end
end
