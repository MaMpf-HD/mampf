require "rails_helper"

RSpec.describe(SearchForm::Services::FilterRegistry, type: :component) do
  # Create a mock class that behaves like SearchForm for testing method generation
  let!(:mock_search_form_class) do
    Class.new do
      attr_reader :fields

      def initialize
        @fields = []
      end

      def with_field(field)
        @fields << field
      end

      # This is needed so the generated methods can find the registry
      def filter_registry
        # This will be stubbed in the tests
      end
    end
  end

  let(:search_form_instance) { mock_search_form_class.new }
  let(:registry) { described_class.new(search_form_instance) }

  before do
    # Ensure the generated methods can access the registry instance
    allow(search_form_instance).to receive(:filter_registry).and_return(registry)
  end

  describe "#initialize" do
    it "stores the search_form instance" do
      expect(registry.instance_variable_get(:@search_form)).to eq(search_form_instance)
    end
  end

  describe ".generate_methods_for" do
    # Generate the methods on our mock class before running the tests
    before do
      described_class.generate_methods_for(mock_search_form_class)
    end

    context "for a simple filter (e.g., :fulltext)" do
      let(:filter_double) { instance_double(SearchForm::Filters::FulltextFilter) }

      before do
        allow(SearchForm::Filters::FulltextFilter).to receive(:new).and_return(filter_double)
      end

      it "defines a standard filter method" do
        expect(search_form_instance).to respond_to(:add_fulltext_filter)
      end

      it "instantiates the correct filter class with options" do
        expect(SearchForm::Filters::FulltextFilter).to receive(:new).with(placeholder: "Search...")
        search_form_instance.add_fulltext_filter(placeholder: "Search...")
      end

      it "adds the filter to the search form" do
        expect(search_form_instance).to receive(:with_field).with(filter_double)
        search_form_instance.add_fulltext_filter
      end

      it "returns the created filter instance" do
        expect(search_form_instance.add_fulltext_filter).to eq(filter_double)
      end
    end

    context "for a filter with additional methods (e.g., :teachable)" do
      let(:filter_double) { instance_double(SearchForm::Filters::TeachableFilter) }
      let(:enhanced_filter_double) { instance_double(SearchForm::Filters::TeachableFilter, "enhanced") }

      before do
        allow(SearchForm::Filters::TeachableFilter).to receive(:new).and_return(filter_double)
        allow(filter_double).to receive(:with_inheritance_radios).and_return(enhanced_filter_double)
      end

      it "defines a standard filter method" do
        expect(search_form_instance).to respond_to(:add_teachable_filter)
      end

      it "defines an enhanced filter method" do
        expect(search_form_instance).to respond_to(:add_teachable_filter_with_inheritance)
      end

      describe "calling the enhanced method" do
        it "instantiates the base filter class" do
          expect(SearchForm::Filters::TeachableFilter).to receive(:new).with(collection: [])
          search_form_instance.add_teachable_filter_with_inheritance(collection: [])
        end

        it "calls the specified chain method" do
          expect(filter_double).to receive(:with_inheritance_radios)
          search_form_instance.add_teachable_filter_with_inheritance
        end

        it "adds the *enhanced* filter to the search form" do
          expect(search_form_instance).to receive(:with_field).with(enhanced_filter_double)
          search_form_instance.add_teachable_filter_with_inheritance
        end

        it "returns the enhanced filter instance" do
          expect(search_form_instance.add_teachable_filter_with_inheritance)
            .to eq(enhanced_filter_double)
        end
      end
    end
  end

  describe "#available_filters" do
    it "returns all keys from the FILTERS constant" do
      expected_filters = described_class::FILTERS.keys
      expect(registry.available_filters).to match_array(expected_filters)
    end

    it "returns a frozen array to prevent modification" do
      expect(registry.available_filters).to be_frozen
    end
  end
end
