require "rails_helper"

RSpec.describe(Search::Searchers::SearchResult) do
  # Use a double for the Pagy object
  let(:pagy) { double("Pagy") }
  # Use a double for the paginated results, which are an ActiveRecord::Relation
  let(:results) { double("ActiveRecord::Relation") }

  describe "#initialize" do
    context "with all required arguments" do
      subject(:search_result) do
        described_class.new(pagy: pagy, results: results)
      end

      it "assigns the pagy object correctly" do
        expect(search_result.pagy).to eq(pagy)
      end

      it "assigns the results correctly" do
        expect(search_result.results).to eq(results)
      end
    end

    context "with missing arguments" do
      it "raises an ArgumentError if pagy is missing" do
        expect { described_class.new(results: results) }
          .to raise_error(ArgumentError)
      end

      it "raises an ArgumentError if results are missing" do
        expect { described_class.new(pagy: pagy) }
          .to raise_error(ArgumentError)
      end
    end
  end
end
