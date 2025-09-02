require "rails_helper"

RSpec.describe(Search::Searchers::SearchResult) do
  let(:results) { double("Kaminari::PaginatableArray") }
  let(:total_count) { 42 }

  describe "#initialize" do
    context "with all required arguments" do
      subject(:search_result) do
        described_class.new(results: results, total_count: total_count)
      end

      it "assigns the results correctly" do
        expect(search_result.results).to eq(results)
      end

      it "assigns the total_count correctly" do
        expect(search_result.total_count).to eq(total_count)
      end
    end

    context "with missing arguments" do
      it "raises an ArgumentError if results are missing" do
        expect { described_class.new(total_count: total_count) }
          .to raise_error(ArgumentError)
      end

      it "raises an ArgumentError if total_count is missing" do
        expect { described_class.new(results: results) }
          .to raise_error(ArgumentError)
      end
    end
  end
end
