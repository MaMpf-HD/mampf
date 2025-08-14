require "rails_helper"

RSpec.describe(Search::Configurators::Configuration) do
  let(:filters) { [double("FilterClass1"), double("FilterClass2")] }
  let(:params) { { key: "value" } }
  let(:sorter_class) { double("SorterClass") }

  describe "#initialize" do
    context "with only required arguments" do
      subject(:config) { described_class.new(filters: filters, params: params) }

      it "assigns the filters correctly" do
        expect(config.filters).to eq(filters)
      end

      it "assigns the params correctly" do
        expect(config.params).to eq(params)
      end

      it "defaults the sorter_class to nil" do
        expect(config.sorter_class).to be_nil
      end
    end

    context "with all arguments" do
      subject(:config) do
        described_class.new(filters: filters,
                            params: params,
                            sorter_class: sorter_class)
      end

      it "assigns the filters correctly" do
        expect(config.filters).to eq(filters)
      end

      it "assigns the params correctly" do
        expect(config.params).to eq(params)
      end

      it "assigns the sorter_class correctly" do
        expect(config.sorter_class).to eq(sorter_class)
      end
    end

    context "with missing arguments" do
      it "raises an ArgumentError if filters are missing" do
        expect { described_class.new(params: params) }
          .to raise_error(ArgumentError)
      end

      it "raises an ArgumentError if params are missing" do
        expect { described_class.new(filters: filters) }
          .to raise_error(ArgumentError)
      end
    end
  end
end
