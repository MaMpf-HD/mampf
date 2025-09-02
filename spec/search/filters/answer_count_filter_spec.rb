require "rails_helper"

RSpec.describe(Search::Filters::AnswerCountFilter) do
  let(:user) { create(:user) }
  let!(:question1) { create(:valid_question, :with_answers, answers_count: 1) }
  let!(:question2) { create(:valid_question, :with_answers, answers_count: 2) }
  let!(:question7) { create(:valid_question, :with_answers, answers_count: 7) }
  let!(:question8) { create(:valid_question, :with_answers, answers_count: 8) }
  let!(:other_medium) { create(:valid_medium, sort: "Remark") }
  let(:scope) { Medium.all }

  subject(:filtered_scope) { described_class.filter(scope: scope, params: params, user: user) }

  context "when the filter is not applicable" do
    context "because answer count is irrelevant" do
      let(:params) { { types: ["Question"], answers_count: "irrelevant" } }

      it "returns the original scope" do
        expect(filtered_scope).to match_array([question1, question2, question7, question8,
                                               other_medium])
      end
    end

    context "because answer count is blank" do
      let(:params) { { types: ["Question"], answers_count: "" } }

      it "returns the original scope" do
        expect(filtered_scope).to match_array([question1, question2, question7, question8,
                                               other_medium])
      end
    end

    context "because types are not exclusively 'Question'" do
      let(:params) { { types: ["Question", "Remark"], answers_count: "2" } }

      it "returns the original scope" do
        expect(filtered_scope).to match_array([question1, question2, question7, question8,
                                               other_medium])
      end
    end
  end

  context "when filtering for a specific number of answers" do
    let(:params) { { types: ["Question"], answers_count: "2" } }

    it "returns only questions with exactly 2 answers" do
      expect(filtered_scope).to contain_exactly(question2)
    end
  end

  context "when filtering for more than 6 answers" do
    let(:params) { { types: ["Question"], answers_count: "7" } }

    it "returns only questions with 7 or more answers" do
      expect(filtered_scope).to contain_exactly(question7, question8)
    end
  end

  context "when no questions match the criteria" do
    let(:params) { { types: ["Question"], answers_count: "5" } }

    it "returns an empty scope" do
      expect(filtered_scope).to be_empty
    end
  end
end
