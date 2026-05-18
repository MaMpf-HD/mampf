require "rails_helper"

RSpec.describe(Search::Filters::TermFilter, type: :filter) do
  describe "#filter" do
    let(:user) { create(:user) }
    let!(:active_term) { create(:term, active: true) }
    let!(:inactive_term) { create(:term) }

    let!(:lecture_in_active_term) { create(:lecture, term: active_term) }
    let!(:lecture_in_inactive_term) { create(:lecture, term: inactive_term) }
    let!(:lecture_with_no_term) { create(:lecture, :term_independent) }

    let(:scope) { Lecture.all }
    let(:all_lectures) { [lecture_in_active_term, lecture_in_inactive_term, lecture_with_no_term] }

    subject(:filtered_scope) { described_class.filter(scope: scope, params: params, user: user) }

    context "when filtering for specific terms" do
      context "and the active term is selected" do
        let(:params) { { term_ids: [active_term.id.to_s] } }

        it "returns lectures from the active term and lectures with no term" do
          expect(filtered_scope).to match_array([lecture_in_active_term, lecture_with_no_term])
        end
      end

      context "and only an inactive term is selected" do
        let(:params) { { term_ids: [inactive_term.id.to_s] } }

        it "returns only lectures from the inactive term" do
          expect(filtered_scope).to contain_exactly(lecture_in_inactive_term)
        end
      end

      context "and multiple terms including the active one are selected" do
        let(:params) { { term_ids: [active_term.id.to_s, inactive_term.id.to_s] } }

        it "returns lectures from all selected terms and lectures with no term" do
          expect(filtered_scope).to match_array(all_lectures)
        end
      end
    end

    context "when no active term exists" do
      before do
        # rubocop:disable Rails/SkipsModelValidations
        Term.update_all(active: false)
        # rubocop:enable Rails/SkipsModelValidations
      end

      let(:params) { { term_ids: [active_term.id.to_s] } }

      it "filters strictly by the provided term_id" do
        expect(filtered_scope).to contain_exactly(lecture_in_active_term)
      end
    end
  end
end
