require "rails_helper"

RSpec.describe(Search::Filters::FulltextFilter, type: :filter) do
  describe "#call" do
    let!(:course1) { create(:course, title: "Introduction to Ruby") }
    let!(:course2) { create(:course, title: "Advanced Ruby Programming") }
    let!(:course3) { create(:course, title: "Web Development with Rails") }
    let(:user) { create(:confirmed_user) }
    let(:scope) { Course.all }

    subject(:filtered_scope) { described_class.new(scope: scope, params: params, user: user).call }

    context "when 'fulltext' parameter is blank" do
      context "with a nil value" do
        let(:params) { { fulltext: nil } }
        it "returns the original scope" do
          expect(filtered_scope).to match_array([course1, course2, course3])
        end
      end

      context "with an empty string" do
        let(:params) { { fulltext: "" } }
        it "returns the original scope" do
          expect(filtered_scope).to match_array([course1, course2, course3])
        end
      end
    end

    context "when 'fulltext' parameter is provided" do
      context "with a full word match" do
        let(:params) { { fulltext: "Ruby" } }
        it "filters the scope based on the search term" do
          expect(filtered_scope).to contain_exactly(course1, course2)
        end
      end

      context "with a partial word match" do
        let(:params) { { fulltext: "Rub" } }
        it "filters the scope based on the prefix" do
          expect(filtered_scope).to contain_exactly(course1, course2)
        end
      end

      context "with a different matching term" do
        let(:params) { { fulltext: "Rails" } }
        it "filters correctly" do
          expect(filtered_scope).to contain_exactly(course3)
        end
      end

      context "with a non-matching term" do
        let(:params) { { fulltext: "Python" } }
        it "returns an empty scope" do
          expect(filtered_scope).to be_empty
        end
      end
    end
  end
end
