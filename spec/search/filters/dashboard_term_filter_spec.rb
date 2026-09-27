require "rails_helper"

RSpec.describe(Search::Filters::DashboardTermFilter, type: :filter) do
  describe "#filter" do
    let(:user) { create(:user) }
    let!(:current_term) { create(:term, :summer, :active, year: 2025) }
    let!(:next_term) { create(:term, :winter, year: 2025) }
    let!(:lecture_in_current_term) { create(:lecture, term: current_term) }
    let!(:lecture_in_next_term) { create(:lecture, term: next_term) }
    let!(:lecture_without_term) { create(:lecture, :term_independent) }
    let(:scope) { Lecture.all }

    subject(:filtered_scope) do
      described_class.filter(scope: scope, params: params, user: user)
    end

    context "with an explicit term slug" do
      let(:params) { { term: next_term.dashboard_param } }

      it "returns that term's lectures plus the term-independent ones" do
        expect(filtered_scope).to contain_exactly(lecture_in_next_term,
                                                  lecture_without_term)
      end
    end

    context "with a bare term id" do
      let(:params) { { term: next_term.id } }

      it "still resolves the term" do
        expect(filtered_scope).to contain_exactly(lecture_in_next_term,
                                                  lecture_without_term)
      end
    end

    context "with no term" do
      let(:params) { {} }

      it "falls back to the active term" do
        expect(filtered_scope).to contain_exactly(lecture_in_current_term,
                                                  lecture_without_term)
      end
    end

    context "when the selected term has no lectures of its own" do
      let(:empty_term) { create(:term, :summer, year: 2026) }
      let(:params) { { term: empty_term.id } }

      it "returns only the term-independent lectures" do
        expect(filtered_scope).to contain_exactly(lecture_without_term)
      end
    end

    context "with neither an id nor an active term" do
      before { current_term.update!(active: false) }

      let(:params) { {} }

      it "leaves the scope untouched" do
        expect(filtered_scope).to match_array([lecture_in_current_term,
                                               lecture_in_next_term,
                                               lecture_without_term])
      end
    end
  end
end
