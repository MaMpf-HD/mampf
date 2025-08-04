require "rails_helper"

# NOTE: The class is now namespaced under Search
RSpec.describe(TeachableParser) do
  let!(:course) { create(:course) }
  let!(:lecture1) { create(:lecture, :with_sparse_toc, course: course) }
  let!(:lecture2) { create(:lecture, course: course) }
  let!(:lesson) { create(:valid_lesson, lecture: lecture1) }

  # Use let for values that can be lazily evaluated.
  let(:course_str) { "Course-#{course.id}" }
  let(:lecture1_str) { "Lecture-#{lecture1.id}" }
  let(:lecture2_str) { "Lecture-#{lecture2.id}" }
  let(:lesson_str) { "Lesson-#{lesson.id}" }

  subject(:call) { described_class.call(params) }

  describe "#call" do
    context "when the 'all_teachables' flag is set" do
      let(:params) { { all_teachables: "1" } }

      it "returns an empty array" do
        expect(call).to eq([])
      end
    end

    context "when the 'teachable_inheritance' flag is disabled" do
      let(:params) do
        {
          teachable_ids: [course_str],
          teachable_inheritance: "0"
        }
      end

      it "returns the original list of teachable IDs" do
        expect(call).to eq([course_str])
      end
    end

    context "when the 'teachable_inheritance' flag is enabled" do
      let(:params) do
        {
          teachable_ids: teachable_ids,
          teachable_inheritance: "1"
        }
      end

      context "with a course ID" do
        let(:teachable_ids) { [course_str] }

        it "returns the course, its lectures, and their lessons" do
          expect(call).to match_array([course_str, lecture1_str, lecture2_str, lesson_str])
        end
      end

      context "with lecture IDs" do
        let(:teachable_ids) { [lecture1_str, lecture2_str] }

        it "returns the lectures and their lessons" do
          expect(call).to match_array([lecture1_str, lecture2_str, lesson_str])
        end
      end
    end
  end
end
