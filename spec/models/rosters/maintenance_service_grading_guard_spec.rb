require "rails_helper"

RSpec.describe(Rosters::MaintenanceService) do
  let(:service) { described_class.new }
  let(:student) { create(:confirmed_user) }
  let(:grader) { create(:confirmed_user) }

  before { Flipper.enable(:assessment_grading) }

  after { Flipper.disable(:assessment_grading) }

  describe "a rosterable that owns its assessment" do
    let(:seminar) { create(:seminar) }
    let(:talk) { create(:talk, lecture: seminar) }
    let(:other_talk) { create(:talk, lecture: seminar) }

    before { talk.add_user_to_roster!(student) }

    def graded_participation
      talk.ensure_assessment!(requires_points: false)
      participation = Assessment::Participation.create!(assessment: talk.assessment,
                                                        user: student)
      participation.update!(grade_numeric: 2.0, grader: grader,
                            graded_at: Time.current, status: :reviewed)
      participation
    end

    it "refuses to remove a speaker who has a grade" do
      graded_participation

      expect { service.remove_user!(student, talk) }
        .to raise_error(described_class::GradingDataPresentError)
      expect(talk.reload.speakers).to include(student)
    end

    it "refuses to move a speaker who has a grade" do
      graded_participation

      expect { service.move_user!(student, talk, other_talk, force: true) }
        .to raise_error(described_class::GradingDataPresentError)
      expect(talk.reload.speakers).to include(student)
      expect(other_talk.reload.speakers).not_to include(student)
    end

    it "still allows removing a speaker whose participation is untouched" do
      talk.ensure_assessment!(requires_points: false)
      Assessment::Participation.create!(assessment: talk.assessment, user: student)

      expect { service.remove_user!(student, talk) }.not_to raise_error
      expect(talk.reload.speakers).not_to include(student)
    end
  end

  describe "a rosterable that only hosts the grading" do
    let(:lecture) { create(:lecture) }
    let(:tutorial) { create(:tutorial, lecture: lecture) }
    let(:other_tutorial) { create(:tutorial, lecture: lecture) }
    let(:assignment) { create(:assignment, lecture: lecture) }

    before { tutorial.add_user_to_roster!(student) }

    # The assessment belongs to the assignment, so the result is not left behind
    # by the move — the tutorial is only where it is graded.
    it "allows moving a student who already has points" do
      assignment.ensure_pointbook!
      task = assignment.assessment.tasks.create!(max_points: 10, position: 1)
      # points may only be entered once the assignment is past its deadline
      assignment.update_column(:deadline, 2.days.ago) # rubocop:disable Rails/SkipsModelValidations
      assignment.reload
      participation = Assessment::Participation.create!(
        assessment: assignment.assessment, user: student, tutorial: tutorial
      )
      Assessment::TaskPoint.create!(assessment_participation: participation,
                                    task: task, points: 7, grader: grader)

      expect { service.move_user!(student, tutorial, other_tutorial, force: true) }
        .not_to raise_error
      expect(other_tutorial.reload.roster_entries.count).to eq(1)
    end
  end
end
