require "rails_helper"

RSpec.describe(Search::Filters::TypeFilter, type: :filter) do
  describe "#call" do
    let(:user) { create(:user) }
    let!(:medium_question) { create(:valid_medium, sort: "Question") }
    let!(:medium_remark) { create(:valid_medium, sort: "Remark") }
    let!(:medium_exercise) { create(:valid_medium, sort: "Exercise") }

    let(:scope) { Medium.all }
    let(:all_media) { [medium_question, medium_remark, medium_exercise] }

    subject(:filtered_scope) { described_class.filter(scope: scope, params: params, user: user) }

    context "when filtering for specific types" do
      context "by a single type" do
        let(:params) { { types: ["Question"] } }

        it "returns only media of that type" do
          expect(filtered_scope).to contain_exactly(medium_question)
        end
      end

      context "by multiple types" do
        let(:params) { { types: ["Question", "Exercise"] } }

        it "returns media of any of the given types" do
          expect(filtered_scope).to match_array([medium_question, medium_exercise])
        end
      end

      context "by a type with no matches" do
        let(:params) { { types: ["Script"] } }

        it "returns an empty scope" do
          expect(filtered_scope).to be_empty
        end
      end
    end
  end
end
