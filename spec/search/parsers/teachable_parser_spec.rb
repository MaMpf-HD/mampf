require "rails_helper"

RSpec.describe(Search::Parsers::TeachableParser) do
  # Create test data
  let!(:course) { create(:course) }
  let!(:lecture1) { create(:lecture, :with_sparse_toc, course: course) }
  let!(:lecture2) { create(:lecture, course: course) }
  let!(:lesson) { create(:valid_lesson, lecture: lecture1) }

  # Use let for values that can be lazily evaluated.
  let(:course_str) { "Course-#{course.id}" }
  let(:lecture1_str) { "Lecture-#{lecture1.id}" }
  let(:lecture2_str) { "Lecture-#{lecture2.id}" }
  let(:lesson_str) { "Lesson-#{lesson.id}" }

  # The main describe block now targets the .parse class method
  describe ".parse" do
    context "when no teachables are provided" do
      # The subject now calls the .parse method
      subject(:parse) { described_class.parse(teachable_ids: []) }

      it "returns an empty hash" do
        expect(parse).to eq({})
      end
    end

    context "when 'all_teachables' is set to true" do
      # The subject now calls the .parse method
      subject(:parse) { described_class.parse(all_teachables: true) }

      it "returns an empty hash" do
        expect(parse).to eq({})
      end
    end

    context "when inheritance is disabled" do
      # The subject now calls the .parse method
      subject(:parse) do
        described_class.parse(
          teachable_ids: [course_str, lecture1_str, lesson_str],
          inheritance: false
        )
      end

      it "returns a hash of exactly the provided teachables" do
        expect(parse).to eq(
          "Course" => [course.id],
          "Lecture" => [lecture1.id],
          "Lesson" => [lesson.id]
        )
      end
    end

    context "when inheritance is enabled" do
      # The subject is defined within each sub-context to pass the correct IDs
      subject(:parse) { described_class.parse(teachable_ids: teachable_ids, inheritance: true) }

      context "with a course" do
        let(:teachable_ids) { [course_str] }

        it "returns the course, all its lectures, and their lessons" do
          expect(parse["Course"]).to contain_exactly(course.id)
          expect(parse["Lecture"].pluck(:id)).to contain_exactly(lecture1.id, lecture2.id)
          expect(parse["Lesson"].pluck(:id)).to contain_exactly(lesson.id)
        end
      end

      context "with a lecture that has a lesson" do
        let(:teachable_ids) { [lecture1_str] }

        it "returns the lecture and its lesson" do
          expect(parse["Course"]).to be_empty
          expect(parse["Lecture"].pluck(:id)).to contain_exactly(lecture1.id)
          expect(parse["Lesson"].pluck(:id)).to contain_exactly(lesson.id)
        end
      end

      context "with a lecture that has no lessons" do
        let(:teachable_ids) { [lecture2_str] }

        it "returns the lecture and no lessons" do
          expect(parse["Course"]).to be_empty
          expect(parse["Lecture"].pluck(:id)).to contain_exactly(lecture2.id)
          expect(parse["Lesson"]).to be_empty
        end
      end

      context "with only a lesson" do
        let(:teachable_ids) { [lesson_str] }

        it "returns only the specified lesson" do
          # When only a lesson is passed, the result is not a subquery.
          expect(parse).to eq(
            "Course" => [],
            "Lecture" => [],
            "Lesson" => [lesson.id]
          )
        end
      end
    end
  end
end
