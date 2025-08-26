require "rails_helper"

RSpec.describe(SearchForm::Filters::PerPageFilter, type: :component) do
  let(:options) { {} }
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

  subject(:filter) do
    field_instance = described_class.new(**options)
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub I18n calls.
    allow(I18n).to receive(:t).with("basics.hits_per_page").and_return("Hits per page")
    allow(I18n).to receive(:t).with("basics.select").and_return("Please select") # From parent

    # Set up mocks for rendering (needed for parent class).
    allow(form_state).to receive(:form).and_return(form_builder)
    allow(form_state).to receive(:with_form).and_return(form_state)
    allow(form_state).to receive(:label_for)
    allow(form_state).to receive(:element_id_for)
    allow(form_builder).to receive(:label)
    allow(form_builder).to receive(:select)
  end

  describe "#initialize" do
    context "with default options" do
      it "initializes with the correct name and label" do
        expect(filter.name).to eq(:per)
        expect(filter.label).to eq("Hits per page")
      end

      it "uses the default collection" do
        expect(filter.collection).to eq([[10, 10], [20, 20], [50, 50]])
      end

      it "uses the default selected value" do
        expect(filter.selected).to eq(10)
      end
    end

    context "with custom options" do
      let(:custom_options) { [[100, 100], [200, 200]] }
      let(:options) { { per_options: custom_options, default: 100 } }

      it "uses the provided custom collection" do
        expect(filter.collection).to eq(custom_options)
      end

      it "uses the provided custom default value" do
        expect(filter.selected).to eq(100)
      end
    end

    context "with additional passthrough options" do
      let(:options) { { container_class: "custom-class" } }

      it "passes the additional options to the superclass" do
        expect(filter.container_class).to eq("custom-class")
      end
    end
  end
end
