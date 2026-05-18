require "rails_helper"

RSpec.describe(SearchForm::Services::FieldRegistry, type: :component) do
  # Create a mock class that behaves like SearchForm for testing method generation
  let!(:mock_search_form_class) do
    Class.new do
      attr_reader :fields, :form_state

      def initialize(form_state:)
        @fields = []
        @form_state = form_state
      end

      def with_field(field)
        @fields << field
      end
    end
  end

  let(:form_state_double) { instance_double(SearchForm::Services::FormState) }
  let(:search_form_instance) { mock_search_form_class.new(form_state: form_state_double) }
  let(:registry) { described_class.new(search_form_instance) }

  describe "#initialize" do
    it "stores the search_form instance" do
      expect(registry.instance_variable_get(:@search_form)).to eq(search_form_instance)
    end
  end

  describe ".generate_methods_for" do
    # Generate the methods on our mock class before running the tests
    before do
      # Stub the constant and define an initializer that accepts keyword arguments
      # to prevent a "Wrong number of arguments" error.
      stub_const("SearchForm::Fields::FulltextField", Class.new do
        def initialize(**_args)
        end
      end)
      described_class.generate_methods_for(mock_search_form_class)
    end

    context "for a simple field (e.g., :fulltext)" do
      let(:field_double) { instance_double(SearchForm::Fields::FulltextField) }

      before do
        allow(SearchForm::Fields::FulltextField).to receive(:new).and_return(field_double)
      end

      it "defines a standard field method" do
        expect(search_form_instance).to respond_to(:add_fulltext_field)
      end

      it "instantiates the correct field class with form_state and options" do
        expect(SearchForm::Fields::FulltextField).to receive(:new)
          .with(form_state: form_state_double, placeholder: "Search...")
        search_form_instance.add_fulltext_field(placeholder: "Search...")
      end

      it "adds the field to the search form via with_field" do
        expect(search_form_instance).to receive(:with_field).with(field_double)
        search_form_instance.add_fulltext_field
      end

      it "returns the created field instance" do
        expect(search_form_instance.add_fulltext_field).to eq(field_double)
      end
    end
  end
end
