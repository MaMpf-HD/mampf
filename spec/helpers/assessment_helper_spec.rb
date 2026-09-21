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
          participated_tutorial_title: nil,
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
          new_tutorial_title: nil
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

      it "says the person joined a group after handing in without one" do
        result = helper.movement_info_for_user_assignment(student, user_movement_map)

        expect(result).to eq(
          I18n.t("assessment.grading_tutorial.user_joined_tutorial", new_tutorial: "Tutorial 2")
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

      it "says the person left the groups after handing in" do
        result = helper.movement_info_for_user_assignment(student, user_movement_map)

        expect(result).to eq(
          I18n.t("assessment.grading_tutorial.user_left_tutorials", old_tutorial: "Tutorial 1")
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
