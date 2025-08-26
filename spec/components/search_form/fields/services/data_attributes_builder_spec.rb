require "rails_helper"

RSpec.describe(SearchForm::Fields::Services::DataAttributesBuilder, type: :component) do
  # The field that the builder serves.
  let(:field) { instance_double(SearchForm::Fields::Field, "field") }

  # The builder instance under test.
  subject(:builder) { described_class.new(field) }

  describe "#select_data_attributes" do
    context "when the field has no custom data options" do
      it "returns the default target" do
        allow(field).to receive(:options).and_return({})
        expect(builder.select_data_attributes).to eq({ search_form_target: "select" })
      end
    end

    context "when the field has custom data options" do
      it "merges the default target with the custom data" do
        custom_data = { controller: "custom", custom_value: "123" }
        allow(field).to receive(:options).and_return({ data: custom_data })

        expected_data = {
          controller: "custom",
          custom_value: "123",
          search_form_target: "select"
        }
        expect(builder.select_data_attributes).to eq(expected_data)
      end
    end
  end

  describe "#checkbox_data_attributes" do
    context "when the field does not implement #all_toggle_data_attributes" do
      it "returns the default target and action" do
        # The instance_double will not respond to the custom method by default.
        expected_data = {
          search_form_target: "allToggle",
          action: "change->search-form#toggleFromCheckbox"
        }
        expect(builder.checkbox_data_attributes).to eq(expected_data)
      end
    end

    context "when the field implements #all_toggle_data_attributes" do
      # Use a generic double here because we are testing behavior with a method
      # that does not exist on the base Field class.
      let(:field) { double("field") }

      it "returns the value from the custom method" do
        custom_data = { controller: "custom-checkbox", action: "custom->action" }
        # We don't need to stub respond_to? because a generic double will
        # respond to any method it's told to.
        allow(field).to receive(:all_toggle_data_attributes).and_return(custom_data)

        expect(builder.checkbox_data_attributes).to eq(custom_data)
      end
    end
  end
end
