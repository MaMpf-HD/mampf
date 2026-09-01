require "rails_helper"

RSpec.describe(AssessmentHelper, type: :helper) do
  let(:lecture) { create(:lecture) }
  let(:tutorial1) { create(:tutorial, lecture: lecture, title: "Tutorial 1") }
  let(:tutorial2) { create(:tutorial, lecture: lecture, title: "Tutorial 2") }

  let(:student) { create(:confirmed_user) }

  let(:assignment1) { create(:assignment, :with_lecture, lecture: lecture) }
  let!(:assessment1) do
    create(:assessment, requires_points: true, assessable: assignment1, lecture: lecture)
  end

  let(:assignment2) do
    create(:assignment, :with_lecture, lecture: lecture)
  end
  let!(:assessment2) do
    create(:assessment, requires_points: true, assessable: assignment2, lecture: lecture)
  end

  describe "#calculate_user_movement_map_assignment" do
    context "when a user has participated in one tutorial but is currently a member of another" do
      before do
        create(:tutorial_membership, tutorial: tutorial2, user: student)
        create(:assessment_participation,
               assessment: assessment1,
               user: student,
               tutorial: tutorial1)
      end

      it "maps the user's participated tutorial and current (new) tutorial" do
        result = helper.calculate_user_movement_map_assignment(assignment1, lecture)

        expect(result[student.id]).to include(
          participated_tutorial_id: tutorial1.id,
          new_tutorial_id: tutorial2.id,
          participated_tutorial_title: "Tutorial 1",
          new_tutorial_title: "Tutorial 2"
        )
      end
    end

    context "when assignment has no assessment" do
      let(:assignment3) do
        create(:assignment, :with_lecture, :without_assessment, lecture: lecture)
      end

      it "returns an empty hash" do
        result = helper.calculate_user_movement_map_assignment(assignment3, lecture)
        expect(result).to eq({})
      end
    end

    context "when user has a membership but no participation for the assignment" do
      before do
        create(:tutorial_membership, tutorial: tutorial2, user: student)
      end

      it "includes the user with nil participated_tutorial values" do
        result = helper.calculate_user_movement_map_assignment(assignment1, lecture)

        expect(result[student.id]).to include(
          participated_tutorial_id: nil,
          new_tutorial_id: tutorial2.id,
          participated_tutorial_title: I18n.t("assessment.grading_tutorial.no_tutorial"),
          new_tutorial_title: "Tutorial 2"
        )
      end
    end

    context "when user participated but has no current membership" do
      before do
        create(:assessment_participation,
               assessment: assessment1,
               user: student,
               tutorial: tutorial1)
      end

      it "includes the user with nil new_tutorial values" do
        result = helper.calculate_user_movement_map_assignment(assignment1, lecture)

        expect(result[student.id]).to include(
          participated_tutorial_id: tutorial1.id,
          new_tutorial_id: nil,
          participated_tutorial_title: "Tutorial 1",
          new_tutorial_title: I18n.t("assessment.grading_tutorial.no_tutorial")
        )
      end
    end

    context "when neither participation nor membership exists for any user" do
      it "returns an empty hash" do
        result = helper.calculate_user_movement_map_assignment(assignment1, lecture)
        expect(result).to eq({})
      end
    end
  end

  describe "#non_submitter_status" do
    context "when movement is nil" do
      it "returns nil" do
        expect(helper.non_submitter_status(nil, tutorial1)).to be_nil
      end
    end

    context "when user never participated (no participation record at all) but has a membership" do
      let(:movement) do
        {
          participated_tutorial_id: nil,
          new_tutorial_id: tutorial2.id,
          submitted_at: nil,
          participated_tutorial_title: nil,
          new_tutorial_title: "Tutorial 2"
        }
      end

      it "allows grading and marking as participated" do
        result = helper.non_submitter_status(movement, tutorial1)

        expect(result).to eq(
          allowed: true,
          mark_participation_allow: true,
          message: I18n.t("assessment.grading_tutorial.no_submission_badge")
        )
      end
    end

    context "when participation tutorial matches current membership tutorial" do
      context "and submitted_at is present (marked as participated)" do
        let(:movement) do
          {
            participated_tutorial_id: tutorial1.id,
            new_tutorial_id: tutorial1.id,
            submitted_at: Time.zone.now,
            participated_tutorial_title: "Tutorial 1",
            new_tutorial_title: "Tutorial 1"
          }
        end

        it "allows grading and allows removing participation" do
          result = helper.non_submitter_status(movement, tutorial1)

          expect(result).to eq(
            allowed: true,
            remove_participation_allow: true,
            message: I18n.t("assessment.grading_tutorial.marked_as_participated_badge")
          )
        end
      end

      context "and submitted_at is nil (backfilled)" do
        let(:movement) do
          {
            participated_tutorial_id: tutorial1.id,
            new_tutorial_id: tutorial1.id,
            submitted_at: nil,
            participated_tutorial_title: "Tutorial 1",
            new_tutorial_title: "Tutorial 1"
          }
        end

        it "allows grading but does not allow removing participation" do
          result = helper.non_submitter_status(movement, tutorial1)

          expect(result).to eq(
            allowed: true,
            remove_participation_allow: false,
            message: I18n.t("assessment.grading_tutorial.no_submission_badge")
          )
        end
      end
    end

    context "when membership and participation tutorials differ" do
      context "when in lecture mode (host_tutorial is nil)" do
        let(:movement) do
          {
            participated_tutorial_id: tutorial1.id,
            new_tutorial_id: tutorial2.id,
            submitted_at: nil,
            participated_tutorial_title: "Tutorial 1",
            new_tutorial_title: "Tutorial 2"
          }
        end

        it "always allows grading with a movement message" do
          result = helper.non_submitter_status(movement, nil)

          expect(result[:allowed]).to be(true)
          expect(result[:message]).to include(
            I18n.t("assessment.grading_tutorial.no_submission_badge")
          )
        end

        it "includes the full movement message text" do
          result = helper.non_submitter_status(movement, nil)

          expect(result[:message]).to eq(
            I18n.t("assessment.grading_tutorial.no_submission_badge") +
            I18n.t("assessment.grading_tutorial.user_moved_tutorial",
                   old_tutorial: "Tutorial 1", new_tutorial: "Tutorial 2")
          )
        end
      end

      context "when in tutor mode (host_tutorial is present)" do
        context "host_tutorial is the tutorial of membership" do
          let(:movement) do
            {
              participated_tutorial_id: tutorial1.id,
              new_tutorial_id: tutorial2.id,
              submitted_at: nil,
              participated_tutorial_title: "Tutorial 1",
              new_tutorial_title: "Tutorial 2"
            }
          end

          it "does not allow grading here" do
            result = helper.non_submitter_status(movement, tutorial2)

            expect(result[:allowed]).to be(false)
            expect(result[:message]).to eq(
              I18n.t("assessment.grading_tutorial.user_moved_tutorial",
                     old_tutorial: "Tutorial 1",
                     new_tutorial: "Tutorial 2")
            )
          end
        end

        context "host_tutorial is the tutorial of participation" do
          let(:movement) do
            {
              participated_tutorial_id: tutorial1.id,
              new_tutorial_id: tutorial2.id,
              submitted_at: nil,
              participated_tutorial_title: "Tutorial 1",
              new_tutorial_title: "Tutorial 2"
            }
          end

          it "allows grading here with a movement message" do
            result = helper.non_submitter_status(movement, tutorial1)

            expect(result[:allowed]).to be(true)
            expect(result[:message]).to include(
              I18n.t("assessment.grading_tutorial.no_submission_badge")
            )
          end
        end

        context "host_tutorial matches neither membership nor participation tutorial" do
          let(:tutorial3) { create(:tutorial, lecture: lecture, title: "Tutorial 3") }
          let(:movement) do
            {
              participated_tutorial_id: tutorial1.id,
              new_tutorial_id: tutorial2.id,
              submitted_at: nil,
              participated_tutorial_title: "Tutorial 1",
              new_tutorial_title: "Tutorial 2"
            }
          end

          it "returns nil (no branch matches)" do
            result = helper.non_submitter_status(movement, tutorial3)
            expect(result).to be_nil
          end
        end
      end
    end

    context "movement titles fall back to 'no tutorial' translation when nil" do
      let(:movement) do
        {
          participated_tutorial_id: tutorial1.id,
          new_tutorial_id: nil,
          submitted_at: nil,
          participated_tutorial_title: "Tutorial 1",
          new_tutorial_title: nil
        }
      end

      it "uses the no_tutorial translation for the missing tutorial title" do
        result = helper.non_submitter_status(movement, nil)

        expect(result[:message]).to include(
          I18n.t("assessment.grading_tutorial.no_tutorial")
        )
      end
    end
  end

  describe "#movement_info_for_user_assignment" do
    context "when user has no entry in the movement map" do
      it "returns nil" do
        result = helper.movement_info_for_user_assignment(student, {})
        expect(result).to be_nil
      end
    end

    context "when user's participated tutorial matches their current tutorial" do
      let(:user_movement_map) do
        {
          student.id => {
            participated_tutorial_id: tutorial1.id,
            new_tutorial_id: tutorial1.id,
            submitted_at: nil,
            participated_tutorial_title: "Tutorial 1",
            new_tutorial_title: "Tutorial 1"
          }
        }
      end

      it "returns nil (no movement to report)" do
        result = helper.movement_info_for_user_assignment(student, user_movement_map)
        expect(result).to be_nil
      end
    end

    context "when user's participated tutorial differs from their current tutorial" do
      let(:user_movement_map) do
        {
          student.id => {
            participated_tutorial_id: tutorial1.id,
            new_tutorial_id: tutorial2.id,
            submitted_at: nil,
            participated_tutorial_title: "Tutorial 1",
            new_tutorial_title: "Tutorial 2"
          }
        }
      end

      it "returns the movement message" do
        result = helper.movement_info_for_user_assignment(student, user_movement_map)

        expect(result).to eq(
          I18n.t("assessment.grading_tutorial.user_moved_tutorial",
                 old_tutorial: "Tutorial 1",
                 new_tutorial: "Tutorial 2")
        )
      end
    end

    context "when participated_tutorial_id is nil and new_tutorial_id is present" do
      let(:user_movement_map) do
        {
          student.id => {
            participated_tutorial_id: nil,
            new_tutorial_id: tutorial2.id,
            submitted_at: nil,
            participated_tutorial_title: nil,
            new_tutorial_title: "Tutorial 2"
          }
        }
      end

      it "returns the movement message using the no_tutorial fallback for the old tutorial" do
        result = helper.movement_info_for_user_assignment(student, user_movement_map)

        expect(result).to eq(
          I18n.t("assessment.grading_tutorial.user_moved_tutorial",
                 old_tutorial: I18n.t("assessment.grading_tutorial.no_tutorial"),
                 new_tutorial: "Tutorial 2")
        )
      end
    end

    context "when new_tutorial_id is nil and participated_tutorial_id is present" do
      let(:user_movement_map) do
        {
          student.id => {
            participated_tutorial_id: tutorial1.id,
            new_tutorial_id: nil,
            submitted_at: nil,
            participated_tutorial_title: "Tutorial 1",
            new_tutorial_title: nil
          }
        }
      end

      it "returns the movement message using the no_tutorial fallback for the new tutorial" do
        result = helper.movement_info_for_user_assignment(student, user_movement_map)

        expect(result).to eq(
          I18n.t("assessment.grading_tutorial.user_moved_tutorial",
                 old_tutorial: "Tutorial 1",
                 new_tutorial: I18n.t("assessment.grading_tutorial.no_tutorial"))
        )
      end
    end

    context "when both participated_tutorial_id and new_tutorial_id are nil" do
      let(:user_movement_map) do
        {
          student.id => {
            participated_tutorial_id: nil,
            new_tutorial_id: nil,
            submitted_at: nil,
            participated_tutorial_title: nil,
            new_tutorial_title: nil
          }
        }
      end

      it "returns nil (both nil counts as no movement)" do
        result = helper.movement_info_for_user_assignment(student, user_movement_map)
        expect(result).to be_nil
      end
    end
  end

  describe "#assessment_frame_src" do
    context "when params[:assessment_id] is blank" do
      before { allow(helper).to receive(:params).and_return({ assessment_tab: "overview" }) }

      it "returns the overview frame src" do
        expect(helper.assessment_frame_src(lecture))
          .to eq(helper.assessment_assessments_path(lecture_id: lecture.id, tab: "overview"))
      end
    end

    context "when params[:assessment_id] is present" do
      before do
        allow(helper).to receive(:params).and_return(
          assessment_id: assessment1.id,
          assessable_type: "Assignment",
          assessable_id: assignment1.id,
          assessment_tab: "grading"
        )
      end

      it "returns the assessment-specific frame src" do
        expect(helper.assessment_frame_src(lecture)).to eq(
          helper.assessment_assessment_path(assessment1.id,
                                            assessable_type: "Assignment",
                                            assessable_id: assignment1.id,
                                            tab: "grading")
        )
      end
    end
  end
end
