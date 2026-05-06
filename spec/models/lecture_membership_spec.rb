require "rails_helper"

RSpec.describe(LectureMembership, type: :model) do
  it "has a valid factory" do
    expect(build(:lecture_membership)).to be_valid
  end

  describe "performance record callbacks" do
    before { Flipper.enable(:assessment_grading) }

    after { Flipper.disable(:assessment_grading) }

    let(:lecture) { FactoryBot.create(:lecture) }
    let(:user) { FactoryBot.create(:confirmed_user) }

    it "creates a performance record when a membership is created" do
      service = instance_double(
        StudentPerformance::ComputationService,
        compute_and_upsert_record_for: nil
      )
      expect(StudentPerformance::ComputationService)
        .to receive(:new).with(lecture: lecture).and_return(service)
      expect(service).to receive(:compute_and_upsert_record_for).with(user)

      FactoryBot.create(:lecture_membership, lecture: lecture, user: user)
    end

    it "removes the performance record when a membership is destroyed" do
      membership = FactoryBot.create(:lecture_membership,
                                     lecture: lecture, user: user)
      expect(StudentPerformance::Record.where(lecture: lecture, user: user))
        .to exist

      membership.destroy!

      expect(StudentPerformance::Record.where(lecture: lecture, user: user))
        .not_to exist
    end
  end
end
