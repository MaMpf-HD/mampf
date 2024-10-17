require "rails_helper"
RSpec.describe(LecturesController, type: :controller) do
  let(:teacher) { FactoryBot.create(:confirmed_user) }
  let(:generic_user) { FactoryBot.create(:confirmed_user) }
  let(:lecture) { FactoryBot.create(:lecture, teacher: teacher) }
  let(:admin) { FactoryBot.create(:confirmed_user, admin: true) }
  let(:editor) { FactoryBot.create(:confirmed_user, edited_lectures: [lecture]) }

  context "As a teacher" do
    before do
      sign_in teacher
    end

    describe "POST #update" do
      it "does not update the teacher" do
        new_teacher = FactoryBot.create(:confirmed_user)
        post(:update, params: { id: lecture.id,
                                lecture: { teacher_id: new_teacher.id } })
        lecture.reload
        expect(lecture.teacher).to eq(teacher)
      end
    end
  end

  context "As an editor" do
    before do
      sign_in editor
    end

    describe "POST #update" do
      it "does not update the teacher" do
        edited_lecture = editor.edited_lectures.first
        new_teacher = FactoryBot.create(:confirmed_user)
        post(:update, params: { id: edited_lecture.id,
                                lecture: { teacher_id: new_teacher.id } })
        lecture.reload
        expect(lecture.teacher).to eq(teacher)
      end
    end
  end

  context "As an admin" do
    before do
      sign_in admin
    end

    describe "POST #update" do
      it "updates the teacher" do
        new_teacher = FactoryBot.create(:confirmed_user)
        post(:update, params: { id: lecture.id,
                                lecture: { teacher_id: new_teacher.id } })
        lecture.reload
        expect(lecture.teacher).to eq(new_teacher)
      end
    end
  end
end
