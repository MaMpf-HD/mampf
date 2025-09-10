require "rails_helper"

RSpec.describe(SearchForm::Fields::Services::CheckboxManager, type: :component) do
  # The field that the manager serves. It needs to act like a MultiSelectField.
  let(:field) { instance_double(SearchForm::Fields::Primitives::MultiSelectField, "field") }

  # The DataAttributesBuilder that gets instantiated inside the manager.
  let(:data_builder) { instance_double(SearchForm::Fields::Services::DataAttributesBuilder, "data_builder") }

  # The manager instance under test.
  subject(:manager) { described_class.new(field) }

  before do
    # Stub the instantiation of DataAttributesBuilder to return our mock.
    allow(SearchForm::Fields::Services::DataAttributesBuilder).to receive(:new)
      .with(field).and_return(data_builder)
  end

  describe "#initialize" do
    it "initializes a DataAttributesBuilder with the field" do
      # This expectation is implicitly tested by the `before` block,
      # but we can make it explicit for clarity.
      expect(SearchForm::Fields::Services::DataAttributesBuilder).to receive(:new).with(field)
      described_class.new(field)
    end
  end

  describe "#setup_default_checkbox" do
    let(:form_state_double) { instance_double(SearchForm::Services::FormState) }
    let(:checkbox_data) { { action: "change->search-form#toggleFromCheckbox" } }

    before do
      # Set up the field double with the methods that will be called.
      allow(field).to receive(:form_state).and_return(form_state_double)
      allow(field).to receive(:all_toggle_name).and_return(:all_items)
      allow(field).to receive(:all_checkbox_label).and_return("All Items")

      # Set up the data_builder double.
      allow(data_builder).to receive(:checkbox_data_attributes).and_return(checkbox_data)

      # Set up a spy for the main action of this method.
      allow(field).to receive(:with_checkbox)
    end

    it "calls with_checkbox on the field with the correct parameters" do
      expected_args = {
        form_state: form_state_double,
        name: :all_items,
        label: "All Items",
        checked: true,
        data: checkbox_data
      }

      expect(field).to receive(:with_checkbox).with(expected_args)
      manager.setup_default_checkbox
    end
  end

  describe "#should_show_checkbox?" do
    context "when the field's checkbox slot is present" do
      it "returns true" do
        # Use a double that responds to `present?` like a real component would.
        checkbox_double = double("CheckboxComponent", present?: true)
        allow(field).to receive(:checkbox).and_return(checkbox_double)
        expect(manager.should_show_checkbox?).to be(true)
      end
    end

    context "when the field's checkbox slot is not present" do
      it "returns false" do
        # A nil object will respond to `present?` with false.
        allow(field).to receive(:checkbox).and_return(nil)
        expect(manager.should_show_checkbox?).to be(false)
      end
    end
  end
end
