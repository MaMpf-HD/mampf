require "rails_helper"

RSpec.describe(Search::Filters::TeachableFilter, type: :filter) do
  describe "#call" do
    let(:user) { create(:user) }

    # Setup a hierarchy of teachables
    let!(:course) { create(:course) }
    let!(:lecture) { create(:lecture) }
    let!(:lesson) { create(:valid_lesson) }

    # Create a medium for each teachable
    let!(:course_medium) { create(:course_medium, teachable: course) }
    let!(:lecture_medium) { create(:lecture_medium, teachable: lecture) }
    let!(:lesson_medium) { create(:lesson_medium, teachable: lesson) }

    # An unrelated medium that should not be in the results
    let!(:other_medium) { create(:lecture_medium) }

    let(:scope) { Medium.all }
    let(:all_media) { [course_medium, lecture_medium, lesson_medium, other_medium] }

    subject(:filtered_scope) { described_class.new(scope: scope, params: params, user: user).call }

    context "when the filter is not applicable" do
      context "because 'teachable_ids' is nil" do
        let(:params) { { teachable_ids: nil } }
        it "returns the original scope" do
          expect(filtered_scope).to match_array(all_media)
        end
      end

      context "because 'teachable_ids' is an empty array" do
        let(:params) { { teachable_ids: [] } }
        it "returns the original scope" do
          expect(filtered_scope).to match_array(all_media)
        end
      end

      context "because 'teachable_ids' contains only blank values" do
        let(:params) { { teachable_ids: ["", nil] } }
        it "returns the original scope" do
          expect(filtered_scope).to match_array(all_media)
        end
      end
    end

    context "when filtering by a single teachable" do
      context "by a Course" do
        let(:params) { { teachable_ids: ["Course-#{course.id}"] } }
        it "returns only media associated with that course" do
          expect(filtered_scope).to contain_exactly(course_medium)
        end
      end

      context "by a Lecture" do
        let(:params) { { teachable_ids: ["Lecture-#{lecture.id}"] } }
        it "returns only media associated with that lecture" do
          expect(filtered_scope).to contain_exactly(lecture_medium)
        end
      end

      context "by a Lesson" do
        let(:params) { { teachable_ids: ["Lesson-#{lesson.id}"] } }
        it "returns only media associated with that lesson" do
          expect(filtered_scope).to contain_exactly(lesson_medium)
        end
      end
    end

    context "when filtering by multiple teachables" do
      let(:params) { { teachable_ids: ["Course-#{course.id}", "Lesson-#{lesson.id}"] } }
      it "returns media associated with any of the given teachables" do
        expect(filtered_scope).to match_array([course_medium, lesson_medium])
      end
    end

    context "when given a mix of valid and invalid teachable strings" do
      let(:params) { { teachable_ids: ["Lecture-#{lecture.id}", "Tag-123", "Invalid-String"] } }
      it "ignores the invalid strings and filters by the valid ones" do
        expect(filtered_scope).to contain_exactly(lecture_medium)
      end
    end

    context "when given only invalid teachable strings" do
      let(:params) { { teachable_ids: ["Tag-123", "Invalid-String"] } }
      it "returns an empty scope" do
        expect(filtered_scope).to be_empty
      end
    end
  end
end
