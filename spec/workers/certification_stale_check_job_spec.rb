require "rails_helper"

RSpec.describe(CertificationStaleCheckJob, type: :worker) do
  let(:lecture) { FactoryBot.create(:lecture, :released_for_all) }
  let(:user) { FactoryBot.create(:confirmed_user) }
  let(:certifier) { FactoryBot.create(:confirmed_user) }

  before do
    FactoryBot.create(:lecture_membership, user: user, lecture: lecture)
  end

  describe "#perform" do
    it "recomputes performance records for the lecture" do
      service = instance_double(StudentPerformance::ComputationService)
      allow(StudentPerformance::ComputationService)
        .to receive(:new).with(lecture: lecture).and_return(service)
      allow(service).to receive(:compute_and_upsert_all_records!)

      described_class.new.perform(lecture.id)

      expect(service).to have_received(:compute_and_upsert_all_records!)
    end

    context "when a certification is stale" do
      before do
        service = instance_double(StudentPerformance::ComputationService)
        allow(StudentPerformance::ComputationService)
          .to receive(:new).with(lecture: lecture).and_return(service)
        allow(service).to receive(:compute_and_upsert_all_records!)

        FactoryBot.create(:student_performance_record,
                          lecture: lecture, user: user,
                          computed_at: 1.hour.ago)

        FactoryBot.create(:student_performance_certification, :passed,
                          lecture: lecture, user: user,
                          certified_by: certifier,
                          certified_at: 2.hours.ago)
      end

      it "logs stale certifications" do
        allow(Rails.logger).to receive(:info)

        described_class.new.perform(lecture.id)

        expect(Rails.logger).to have_received(:info).with(
          a_string_matching(/stale_count=1/)
        )
      end
    end

    context "when no certification is stale" do
      before do
        service = instance_double(StudentPerformance::ComputationService)
        allow(StudentPerformance::ComputationService)
          .to receive(:new).with(lecture: lecture).and_return(service)
        allow(service).to receive(:compute_and_upsert_all_records!)

        FactoryBot.create(:student_performance_record,
                          lecture: lecture, user: user,
                          computed_at: 2.hours.ago)

        FactoryBot.create(:student_performance_certification, :passed,
                          lecture: lecture, user: user,
                          certified_by: certifier,
                          certified_at: 1.hour.ago)
      end

      it "does not log anything about staleness" do
        allow(Rails.logger).to receive(:info)

        described_class.new.perform(lecture.id)

        expect(Rails.logger).not_to have_received(:info).with(
          a_string_matching(/CertificationStaleCheck/)
        )
      end
    end
  end

  describe "sidekiq_options" do
    it "uses the default queue" do
      expect(described_class.sidekiq_options["queue"]).to eq(:default)
    end

    it "retries once" do
      expect(described_class.sidekiq_options["retry"]).to eq(1)
    end
  end
end
