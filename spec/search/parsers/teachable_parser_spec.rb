require "rails_helper"

RSpec.describe(Search::Parsers::TeachableParser) do
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
    context "when no teachables are provided" do
      let(:params) { { teachable_ids: [] } }
      it "returns an empty hash" do
        expect(call).to eq({})
      end
    end

    context "when 'all_teachables' is set" do
      let(:params) { { all_teachables: "1" } }
      it "returns an empty hash" do
        expect(call).to eq({})
      end
    end

    context "when inheritance is disabled" do
      let(:params) do
        {
          teachable_ids: [course_str, lecture1_str, lesson_str],
          teachable_inheritance: "0"
        }
      end

      it "returns a hash of exactly the provided teachables" do
        expect(call).to eq(
          "Course" => [course.id],
          "Lecture" => [lecture1.id],
          "Lesson" => [lesson.id]
        )
      end
    end

    context "when inheritance is enabled" do
      let(:params) do
        {
          teachable_ids: teachable_ids,
          teachable_inheritance: "1"
        }
      end

      context "with a course" do
        let(:teachable_ids) { [course_str] }

        it "returns the course, all its lectures, and their lessons" do
          expect(call["Course"]).to contain_exactly(course.id)
          expect(call["Lecture"].pluck(:id)).to contain_exactly(lecture1.id, lecture2.id)
          expect(call["Lesson"].pluck(:id)).to contain_exactly(lesson.id)
        end
      end

      context "with a lecture that has a lesson" do
        let(:teachable_ids) { [lecture1_str] }

        it "returns the lecture and its lesson" do
          expect(call["Course"]).to be_empty
          expect(call["Lecture"].pluck(:id)).to contain_exactly(lecture1.id)
          expect(call["Lesson"].pluck(:id)).to contain_exactly(lesson.id)
        end
      end

      context "with a lecture that has no lessons" do
        let(:teachable_ids) { [lecture2_str] }

        it "returns the lecture and no lessons" do
          expect(call["Course"]).to be_empty
          expect(call["Lecture"].pluck(:id)).to contain_exactly(lecture2.id)
          expect(call["Lesson"]).to be_empty
        end
      end

      context "with only a lesson" do
        let(:teachable_ids) { [lesson_str] }

        it "returns only the specified lesson" do
          # When only a lesson is passed, the result is not a subquery.
          expect(call).to eq(
            "Course" => [],
            "Lecture" => [],
            "Lesson" => [lesson.id]
          )
        end
      end
    end
  end
end
