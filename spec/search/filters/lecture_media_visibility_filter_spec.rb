require "rails_helper"

RSpec.describe(Search::Filters::LectureMediaVisibilityFilter) do
  let(:admin) { create(:user, admin: true) }
  let(:editor) { create(:user) }
  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let(:lecture) { create(:lecture_with_toc, course: course, editor_ids: [editor.id]) }
  let(:lesson) { create(:valid_lesson, lecture: lecture) }
  let(:initial_scope) { Medium.all }
  let(:params) { { visibility: visibility, id: lecture.id } }

  # Media for testing
  let!(:course_medium) { create(:course_medium, teachable: course) }
  let!(:lecture_medium) { create(:lecture_medium, teachable: lecture) }
  let!(:lesson_medium) { create(:lesson_medium, teachable: lesson) }
  let(:all_media) { [course_medium, lecture_medium, lesson_medium] }

  subject(:filtered_scope) do
    described_class.filter(scope: initial_scope, params: params, user: current_user)
  end

  context "when filter should be bypassed" do
    let(:current_user) { user }

    context "with blank visibility" do
      let(:visibility) { "" }
      it "returns the original scope" do
        expect(filtered_scope).to match_array(all_media)
      end
    end

    context "with 'all' visibility" do
      let(:visibility) { "all" }
      it "returns the original scope" do
        expect(filtered_scope).to match_array(all_media)
      end
    end

    context "with missing lecture id" do
      let(:visibility) { "lecture" }
      let(:params) { { visibility: visibility, id: nil } }
      it "returns the original scope" do
        expect(filtered_scope).to match_array(all_media)
      end
    end

    context "with non-existent lecture id" do
      let(:visibility) { "lecture" }
      let(:params) { { visibility: visibility, id: -1 } }
      it "returns the original scope" do
        expect(filtered_scope).to match_array(all_media)
      end
    end
  end

  context "when visibility is 'lecture'" do
    let(:visibility) { "lecture" }
    let(:current_user) { user }

    it "excludes media whose teachable is a Course" do
      expect(filtered_scope).not_to include(course_medium)
    end

    it "includes media whose teachable is the Lecture or its Lesson" do
      expect(filtered_scope).to contain_exactly(lecture_medium, lesson_medium)
    end
  end

  context "when visibility is 'thematic'" do
    let(:visibility) { "thematic" }
    let(:lecture_tag) { create(:tag) }
    let!(:course_medium_with_matching_tag) do
      create(:course_medium, teachable: course, tags: [lecture_tag])
    end
    let!(:course_medium_with_other_tag) { create(:course_medium, teachable: course) }

    before do
      # To give a lecture a tag, we must associate the tag with a section
      # that belongs to a chapter of the lecture. `lecture.tags` is a computed
      # property, not a direct association.
      chapter = create(:chapter, lecture: lecture)
      section = create(:section, chapter: chapter)
      section.tags << lecture_tag
    end

    context "for an admin" do
      let(:current_user) { admin }
      it "returns the original scope" do
        expect(filtered_scope).to match_array(all_media + [course_medium_with_matching_tag,
                                                           course_medium_with_other_tag])
      end
    end

    context "for a lecture editor" do
      let(:current_user) { editor }
      it "returns the original scope" do
        expect(filtered_scope).to match_array(all_media + [course_medium_with_matching_tag,
                                                           course_medium_with_other_tag])
      end
    end

    context "for a regular user" do
      let(:current_user) { user }

      it "includes all non-course media" do
        expect(filtered_scope).to include(lecture_medium, lesson_medium)
      end

      it "includes course media that share a tag with the lecture" do
        expect(filtered_scope).to include(course_medium_with_matching_tag)
      end

      it "excludes course media that do not share a tag with the lecture" do
        expect(filtered_scope).not_to include(course_medium_with_other_tag)
      end

      it "returns the correct total set of media" do
        expect(filtered_scope).to contain_exactly(
          lecture_medium,
          lesson_medium,
          course_medium_with_matching_tag
        )
      end
    end
  end
end
