require "rails_helper"

RSpec.describe(Search::Filters::ProperFilter, type: :filter) do
  describe "#call" do
    let(:user) { create(:user) }
    subject(:filtered_scope) { described_class.new(scope, {}, user: user).call }

    context "when the model responds to the .proper scope" do
      # The Medium model's .proper scope filters out 'RandomQuiz' media.
      let!(:proper_video) { create(:valid_medium, sort: "WorkedExample") }
      let!(:proper_question) { create(:valid_medium, sort: "Question") }
      let!(:improper_random_quiz) { create(:valid_medium, sort: "RandomQuiz") }
      let(:scope) { Medium.all }

      it "filters out media of sort 'RandomQuiz'" do
        expect(filtered_scope).not_to include(improper_random_quiz)
      end

      it "does not filter out other media sorts" do
        expect(filtered_scope).to include(proper_video, proper_question)
      end
    end

    context "when the model does not respond to the .proper scope" do
      # The Course model does not define a .proper scope.
      let!(:course1) { create(:course) }
      let!(:course2) { create(:course) }
      let(:scope) { Course.all }

      it "returns the original scope unmodified" do
        expect(filtered_scope).to match_array([course1, course2])
      end
    end
  end
end
