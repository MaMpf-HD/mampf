require "rails_helper"

RSpec.describe(SubmissionsController, "#sync_assessment_participations") do
  include ActiveSupport::Testing::TimeHelpers

  let(:lecture) { create(:lecture, :released_for_all) }
  let(:tutorial) { create(:tutorial, lecture: lecture) }
  let(:user) { create(:confirmed_user) }
  let(:assignment) do
    create(:assignment, lecture: lecture, deadline: 1.week.from_now,
                        deletion_date: 2.months.from_now)
  end
  let(:submission) do
    sub = create(:submission, tutorial: tutorial, assignment: assignment)
    sub.users << user
    sub
  end

  let(:controller_instance) do
    ctrl = described_class.new
    ctrl.instance_variable_set(:@submission, submission)
    ctrl
  end

  before do
    create(:tutorial_membership, user: user, tutorial: tutorial)
  end

  context "when assessment_grading flag is enabled" do
    before { Flipper.enable(:assessment_grading) }
    after { Flipper.disable(:assessment_grading) }

    it "creates a participation on first submission" do
      expect do
        controller_instance.send(:sync_assessment_participations)
      end.to change(Assessment::Participation, :count).by(1)

      participation = Assessment::Participation.last
      expect(participation.user).to eq(user)
      expect(participation.assessment).to eq(assignment.assessment)
      expect(participation.tutorial_id).to eq(tutorial.id)
      expect(participation.status).to eq("pending")
      expect(participation.submitted_at).to be_present
    end

    it "updates submitted_at on re-submission" do
      controller_instance.send(:sync_assessment_participations)
      first_submitted = Assessment::Participation.last.submitted_at

      travel_to 1.hour.from_now do
        controller_instance.send(:sync_assessment_participations)
      end

      expect(Assessment::Participation.count).to eq(1)
      expect(Assessment::Participation.last.submitted_at).to be > first_submitted
    end

    it "creates participations for all team members" do
      partner = create(:confirmed_user)
      create(:tutorial_membership, user: partner, tutorial: tutorial)
      submission.users << partner

      expect do
        controller_instance.send(:sync_assessment_participations)
      end.to change(Assessment::Participation, :count).by(2)

      user_ids = Assessment::Participation.pluck(:user_id)
      expect(user_ids).to contain_exactly(user.id, partner.id)
    end

    it "creates participation for a specific user on join" do
      joiner = create(:confirmed_user)
      other_tutorial = create(:tutorial, lecture: lecture)
      create(:tutorial_membership, user: joiner, tutorial: other_tutorial)
      submission.users << joiner

      expect do
        controller_instance.send(:sync_assessment_participations,
                                 users: [joiner])
      end.to change(Assessment::Participation, :count).by(1)

      participation = Assessment::Participation.last
      expect(participation.user).to eq(joiner)
      expect(participation.tutorial_id).to eq(other_tutorial.id)
    end

    it "does nothing when assignment has no assessment" do
      assignment.assessment.destroy!
      assignment.reload

      expect do
        controller_instance.send(:sync_assessment_participations)
      end.not_to change(Assessment::Participation, :count)
    end

    it "does not overwrite tutorial_id on re-submission" do
      controller_instance.send(:sync_assessment_participations)

      new_tutorial = create(:tutorial, lecture: lecture)
      TutorialMembership.find_by(user: user).update!(tutorial: new_tutorial)

      controller_instance.send(:sync_assessment_participations)

      expect(Assessment::Participation.last.tutorial_id).to eq(tutorial.id)
    end
  end

  context "when assessment_grading flag is disabled" do
    before { Flipper.disable(:assessment_grading) }

    it "does not create any participations" do
      expect do
        controller_instance.send(:sync_assessment_participations)
      end.not_to change(Assessment::Participation, :count)
    end
  end

  describe "#clear_submitted_at" do
    before { Flipper.enable(:assessment_grading) }
    after { Flipper.disable(:assessment_grading) }

    it "clears submitted_at on destroy for all submission users" do
      controller_instance.send(:sync_assessment_participations,
                               users: [user])

      expect(Assessment::Participation.last.submitted_at).to be_present

      controller_instance.send(:clear_submitted_at, [user])

      expect(Assessment::Participation.last.submitted_at).to be_nil
    end

    it "clears submitted_at only for the leaving user" do
      partner = create(:confirmed_user)
      create(:tutorial_membership, user: partner, tutorial: tutorial)
      submission.users << partner

      controller_instance.send(:sync_assessment_participations)

      controller_instance.send(:clear_submitted_at, [user])

      user_p = Assessment::Participation.find_by(user: user)
      partner_p = Assessment::Participation.find_by(user: partner)

      expect(user_p.submitted_at).to be_nil
      expect(partner_p.submitted_at).to be_present
    end

    it "does nothing when flag is disabled" do
      controller_instance.send(:sync_assessment_participations,
                               users: [user])
      Flipper.disable(:assessment_grading)

      controller_instance.send(:clear_submitted_at, [user])

      expect(Assessment::Participation.last.submitted_at).to be_present
    end
  end
end
