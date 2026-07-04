require "rails_helper"

RSpec.describe(Search::Filters::SemesterFilter, type: :filter) do
  describe "#filter" do
    let(:user) { create(:user) }
    let!(:current_term) { create(:term, :summer, :active, year: 2025) }
    let!(:next_term) { create(:term, :winter, year: 2025) }
    let!(:lecture_in_current_term) { create(:lecture, term: current_term) }
    let!(:lecture_in_next_term) { create(:lecture, term: next_term) }
    let!(:lecture_without_term) { create(:lecture, :term_independent) }
    let(:scope) { Lecture.all }

    subject(:filtered_scope) { described_class.filter(scope: scope, params: params, user: user) }

    context "when filtering for the current semester" do
      let(:params) { { semester: "current" } }

      it "returns only lectures in the active term" do
        expect(filtered_scope).to contain_exactly(lecture_in_current_term)
      end
    end

    context "when filtering for the next semester" do
      let(:params) { { semester: "next" } }

      it "returns only lectures in the term after the active term" do
        expect(filtered_scope).to contain_exactly(lecture_in_next_term)
      end
    end

    context "when there is no next term" do
      before { next_term.destroy! }

      let(:params) { { semester: "next" } }

      it "returns no lectures" do
        expect(filtered_scope).to be_empty
      end
    end

    context "when no semester filter is selected" do
      let(:params) { {} }

      it "returns the unmodified scope" do
        expect(filtered_scope).to match_array([
                                                lecture_in_current_term,
                                                lecture_in_next_term,
                                                lecture_without_term
                                              ])
      end
    end
  end
end
