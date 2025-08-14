require "rails_helper"

RSpec.describe(Search::Filters::TermIndependenceFilter, type: :filter) do
  describe "#call" do
    let(:user) { create(:user) }
    # The Course model has a `term_independent` attribute.
    let!(:term_independent_course) { create(:course, term_independent: true) }
    let!(:regular_course) { create(:course, term_independent: false) }

    let(:scope) { Course.all }
    let(:all_courses) { [term_independent_course, regular_course] }

    subject(:filtered_scope) { described_class.filter(scope: scope, params: params, user: user) }

    context "when the filter is not active" do
      context "because 'term_independent' is not '1'" do
        let(:params) { { term_independent: "0" } }

        it "returns the original scope" do
          expect(filtered_scope).to match_array(all_courses)
        end
      end

      context "because 'term_independent' is blank" do
        let(:params) { { term_independent: "" } }

        it "returns the original scope" do
          expect(filtered_scope).to match_array(all_courses)
        end
      end

      context "because 'term_independent' is not in params" do
        let(:params) { {} }

        it "returns the original scope" do
          expect(filtered_scope).to match_array(all_courses)
        end
      end
    end

    context "when the filter is active" do
      context "because 'term_independent' is '1'" do
        let(:params) { { term_independent: "1" } }

        it "returns only term-independent records" do
          expect(filtered_scope).to contain_exactly(term_independent_course)
        end
      end
    end
  end
end
