require "rails_helper"

RSpec.describe(Search::Filters::CurrentNextTermFilter, type: :filter) do
  describe "#filter" do
    let(:user) { create(:user) }
    let!(:current_term) { create(:term, :summer, :active, year: 2025) }
    let!(:next_term) { create(:term, :winter, year: 2025) }
    let!(:lecture_in_current_term) { create(:lecture, term: current_term) }
    let!(:lecture_in_next_term) { create(:lecture, term: next_term) }
    let!(:lecture_without_term) { create(:lecture, :term_independent) }
    let(:scope) { Lecture.all }

    subject(:filtered_scope) { described_class.filter(scope: scope, params: params, user: user) }

    context "when filtering for the current term" do
      let(:params) { { term_scope: "current" } }

      it "returns lectures in the active term and term-independent lectures" do
        expect(filtered_scope).to contain_exactly(
          lecture_in_current_term,
          lecture_without_term
        )
      end
    end

    context "when filtering for the next term" do
      let(:params) { { term_scope: "next" } }

      it "returns lectures in the next term and term-independent lectures" do
        expect(filtered_scope).to contain_exactly(
          lecture_in_next_term,
          lecture_without_term
        )
      end
    end

    context "when there is no next term" do
      before { next_term.destroy! }

      let(:params) { { term_scope: "next" } }

      it "returns term-independent lectures" do
        expect(filtered_scope).to contain_exactly(lecture_without_term)
      end
    end

    context "when no term filter is selected" do
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
