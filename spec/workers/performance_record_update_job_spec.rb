require "rails_helper"

RSpec.describe(PerformanceRecordUpdateJob, type: :worker) do
  let(:lecture) { FactoryBot.create(:lecture, :released_for_all) }
  let(:user) { FactoryBot.create(:confirmed_user) }

  before do
    FactoryBot.create(:lecture_membership, user: user, lecture: lecture)
  end

  describe "#perform" do
    context "with user_id" do
      it "computes a record for the given user" do
        described_class.new.perform(lecture.id, user.id)

        record = StudentPerformance::Record.find_by(
          lecture: lecture, user: user
        )
        expect(record).to be_present
        expect(record.computed_at).to be_within(1.second).of(Time.current)
      end
    end

    context "without user_id" do
      let(:user2) { FactoryBot.create(:confirmed_user) }

      before do
        FactoryBot.create(:lecture_membership, user: user2, lecture: lecture)
      end

      it "computes records for all lecture members" do
        described_class.new.perform(lecture.id)

        expect(
          StudentPerformance::Record.where(lecture: lecture).count
        ).to eq(2)
      end
    end

    it "delegates to ComputationService for single user" do
      service = instance_double(StudentPerformance::ComputationService)
      allow(StudentPerformance::ComputationService)
        .to receive(:new).with(lecture: lecture).and_return(service)
      expect(service).to receive(:compute_and_upsert_record_for).with(user)

      described_class.new.perform(lecture.id, user.id)
    end

    it "delegates to ComputationService for full lecture" do
      service = instance_double(StudentPerformance::ComputationService)
      allow(StudentPerformance::ComputationService)
        .to receive(:new).with(lecture: lecture).and_return(service)
      expect(service).to receive(:compute_and_upsert_all_records!)

      described_class.new.perform(lecture.id)
    end
  end

  describe "sidekiq_options" do
    it "uses the default queue" do
      expect(described_class.sidekiq_options["queue"]).to eq(:default)
    end

    it "retries 3 times" do
      expect(described_class.sidekiq_options["retry"]).to eq(3)
    end
  end
end
