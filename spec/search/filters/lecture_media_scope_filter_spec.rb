require "rails_helper"

RSpec.describe(Search::Filters::LectureMediaScopeFilter) do
  let(:user) { create(:user) }
  let(:initial_scope) { Medium.all }
  let(:params) { { id: lecture.id, project: project_name } }
  let(:project_name) { "LessonMaterial" }
  let!(:course) { create(:course) }
  let!(:lecture) { create(:lecture_with_toc, course: course) }
  let!(:lesson) { create(:valid_lesson, lecture: lecture) }

  subject(:filtered_scope) do
    described_class.filter(scope: initial_scope, params: params, user: user)
  end

  context "with invalid parameters" do
    context "when lecture_id is missing" do
      let(:params) { { project: project_name } }
      it "returns an empty scope" do
        expect(filtered_scope).to be_empty
      end
    end

    context "when project is missing" do
      let(:params) { { lecture_id: lecture.id } }
      it "returns an empty scope" do
        expect(filtered_scope).to be_empty
      end
    end

    context "when lecture is not found" do
      let(:params) { { lecture_id: -1, project: project_name } }
      it "returns an empty scope" do
        expect(filtered_scope).to be_empty
      end
    end
  end

  context "with valid parameters" do
    # Media that should be found
    let!(:course_medium) { create(:course_medium, teachable: course, sort: project_name) }
    let!(:lecture_medium) { create(:lecture_medium, teachable: lecture, sort: project_name) }
    let!(:lesson_medium) { create(:lesson_medium, teachable: lesson, sort: project_name) }

    # Media that should NOT be found
    let!(:wrong_project_medium) do
      create(:lecture_medium, teachable: lecture, sort: "WorkedExample")
    end
    let!(:unrelated_course) { create(:course) }
    let!(:unrelated_medium) do
      create(:course_medium, teachable: unrelated_course, sort: project_name)
    end

    it "returns a scope containing all media associated with the lecture's project" do
      expect(filtered_scope).to contain_exactly(
        course_medium,
        lecture_medium,
        lesson_medium
      )
    end

    it "does not include media from other projects" do
      expect(filtered_scope).not_to include(wrong_project_medium)
    end

    it "does not include media from unrelated teachables" do
      expect(filtered_scope).not_to include(unrelated_medium)
    end
  end
end
