require "rails_helper"

RSpec.describe(Search::Filters::TeacherFilter, type: :filter) do
  describe "#call" do
    let!(:teacher1) { create(:user) }
    let!(:teacher2) { create(:user) }
    let!(:teacher_with_no_lectures) { create(:user) }

    let!(:lecture1) { create(:lecture, teacher: teacher1) }
    let!(:lecture2) { create(:lecture, teacher: teacher2) }
    let!(:lecture3) { create(:lecture, teacher: teacher2) }

    let(:user) { create(:user) }
    let(:scope) { Lecture.all }
    let(:all_lectures) { [lecture1, lecture2, lecture3] }

    subject(:filtered_scope) { described_class.new(scope, params, user: user).call }

    context "when filtering for specific teachers" do
      context "by a single teacher" do
        let(:params) { { teacher_ids: [teacher1.id] } }

        it "returns only lectures from that teacher" do
          expect(filtered_scope).to contain_exactly(lecture1)
        end
      end

      context "by another teacher with multiple lectures" do
        let(:params) { { teacher_ids: [teacher2.id] } }

        it "returns all lectures from that teacher" do
          expect(filtered_scope).to match_array([lecture2, lecture3])
        end
      end

      context "by multiple teachers" do
        let(:params) { { teacher_ids: [teacher1.id, teacher2.id] } }

        it "returns lectures from any of the given teachers" do
          expect(filtered_scope).to match_array(all_lectures)
        end
      end

      context "by a teacher with no lectures" do
        let(:params) { { teacher_ids: [teacher_with_no_lectures.id] } }

        it "returns an empty scope" do
          expect(filtered_scope).to be_empty
        end
      end
    end
  end
end
