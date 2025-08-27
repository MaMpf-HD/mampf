require "rails_helper"

RSpec.describe(Search::Filters::ProgramFilter, type: :filter) do
  describe "#filter" do
    let(:user) { create(:user) }
    let!(:program1) { create(:program) }
    let!(:program2) { create(:program) }
    let!(:division1) { create(:division, program: program1) }
    let!(:division2) { create(:division, program: program2) }

    subject(:filtered_scope) { described_class.filter(scope: scope, params: params, user: user) }

    context "when filtering Course records" do
      let!(:course1) { create(:course, divisions: [division1]) }
      let!(:course2) { create(:course, divisions: [division2]) }
      let!(:course_without_program) { create(:course) }
      let(:scope) { Course.all }
      let(:all_courses) { [course1, course2, course_without_program] }

      context "when filtering by a single program" do
        let(:params) { { program_ids: [program1.id] } }
        it "returns only courses associated with the given program" do
          expect(filtered_scope).to contain_exactly(course1)
        end
      end

      context "when filtering by multiple programs" do
        let(:params) { { program_ids: [program1.id, program2.id] } }
        it "returns courses from any of the given programs" do
          expect(filtered_scope).to contain_exactly(course1, course2)
        end
      end
    end

    context "when filtering Lecture records" do
      let!(:course1) { create(:course, divisions: [division1]) }
      let!(:course2) { create(:course, divisions: [division2]) }
      let!(:lecture1) { create(:lecture, course: course1) }
      let!(:lecture2) { create(:lecture, course: course2) }
      let(:scope) { Lecture.all }

      context "when filtering by program" do
        let(:params) { { program_ids: [program1.id] } }
        it "returns only lectures whose courses are in the given program" do
          expect(filtered_scope).to contain_exactly(lecture1)
        end
      end
    end

    context "when filtering an unsupported model" do
      let!(:tag) { create(:tag) }
      let(:scope) { Tag.all }
      let(:params) { { program_ids: [program1.id] } }

      it "returns the original scope unmodified" do
        expect(filtered_scope).to contain_exactly(tag)
      end
    end
  end
end
