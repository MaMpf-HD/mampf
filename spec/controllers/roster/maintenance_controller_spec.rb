require "rails_helper"

RSpec.describe(Roster::MaintenanceController, type: :controller) do
  let(:user) { create(:user) }
  let(:lecture) { create(:lecture, teacher: user) }
  let(:tutorial) { create(:tutorial, lecture: lecture, manual_roster_mode: true) }
  let(:student) { create(:user) }

  before do
    sign_in(user)
  end

  describe "PATCH #move_member" do
    let(:target_tutorial) { create(:tutorial, lecture: lecture, manual_roster_mode: true) }
    let(:cohort) { create(:cohort, context: lecture, manual_roster_mode: true) }

    before do
      tutorial.members << student
    end

    context "when moving to another tutorial" do
      it "moves the student" do
        expect do
          patch(:move_member, params: {
                  lecture_id: lecture.id,
                  type: "Tutorial",
                  tutorial_id: tutorial.id,
                  user_id: student.id,
                  target_id: target_tutorial.id,
                  target_type: "Tutorial"
                })
        end.to change { tutorial.members.count }.by(-1)
                                                .and(change { target_tutorial.members.count }.by(1))
      end
    end

    context "when moving to a cohort" do
      it "moves the student" do
        expect do
          patch(:move_member, params: {
                  lecture_id: lecture.id,
                  type: "Tutorial",
                  tutorial_id: tutorial.id,
                  user_id: student.id,
                  target_id: cohort.id,
                  target_type: "Cohort"
                })
        end.to change { tutorial.members.count }.by(-1)
                                                .and(change { cohort.members.count }.by(1))
      end
    end

    context "when target is locked" do
      before do
        allow(target_tutorial).to receive(:locked?).and_return(true)
        allow(Tutorial).to receive(:find_by).with(id: target_tutorial.id.to_s,
                                                  lecture: lecture).and_return(target_tutorial)
        # We need to mock the find_by for the source tutorial as well because
        # the controller re-fetches it
        allow(Tutorial).to receive(:find_by).with(id: tutorial.id.to_s).and_return(tutorial)
      end

      it "does not move the student" do
        expect do
          patch(:move_member, params: {
                  lecture_id: lecture.id,
                  type: "Tutorial",
                  tutorial_id: tutorial.id,
                  user_id: student.id,
                  target_id: target_tutorial.id,
                  target_type: "Tutorial"
                })
        end.not_to(change { tutorial.members.count })

        expect(flash[:alert]).to eq(I18n.t("roster.errors.target_locked"))
      end
    end
  end
end
