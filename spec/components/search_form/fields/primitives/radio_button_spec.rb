require "rails_helper"

RSpec.describe(SearchForm::Fields::Primitives::RadioButtonField, type: :component) do
  let(:form_state_double) { instance_double(SearchForm::Services::FormState, "form_state") }
  let(:field_data_double) { instance_double(SearchForm::Fields::Services::FieldData, "field_data") }
  let(:minimal_args) do
    {
      name: :test_radio,
      value: "option1",
      label: "Option 1",
      form_state: form_state_double
    }
  end

  subject(:field) { described_class.new(**minimal_args) }

  before do
    # Stub the FieldData creation to isolate the component for most tests.
    allow(SearchForm::Fields::Services::FieldData).to receive(:new).and_return(field_data_double)
    allow(field_data_double).to receive(:define_singleton_method)
    allow(field_data_double).to receive(:extract_and_update_field_classes!)

    # Stub delegations from the mixin that are used by the component's methods.
    allow(field).to receive(:form_state).and_return(form_state_double)
    allow(field).to receive(:name).and_return(:test_radio)
    allow(field).to receive(:options).and_return({})
    allow(field).to receive(:show_help_text?).and_return(false)

    # Stub ID generation methods that rely on form_state. Radio buttons include the value.
    allow(form_state_double).to receive(:element_id_for).with(:test_radio, value: "option1")
                                                        .and_return("form_test_radio_option1")
    allow(form_state_double).to receive(:label_for).with(:test_radio, value: "option1")
                                                   .and_return("form_test_radio_option1_label")
  end

  describe "#initialize" do
    it "sets checked to false by default" do
      expect(field.checked).to be(false)
    end

    it "assigns the checked value when provided" do
      instance = described_class.new(**minimal_args, checked: true)
      expect(instance.checked).to be(true)
    end

    it "correctly passes arguments to FieldData.new" do
      # Un-stub the FieldData.new for this specific test
      allow(SearchForm::Fields::Services::FieldData).to receive(:new).and_call_original

      expect(SearchForm::Fields::Services::FieldData).to receive(:new)
        .with(
          name: :test_radio,
          label: "Option 1",
          form_state: form_state_double,
          help_text: "Help!",
          # The mixin collects all remaining kwargs, including help_text, into the options hash.
          options: { help_text: "Help!", inline: true }
        )

      described_class.new(**minimal_args, help_text: "Help!", inline: true)
    end
  end

  describe "#container_class" do
    it "returns the custom class if provided" do
      instance = described_class.new(**minimal_args, container_class: "custom-class")
      expect(instance.container_class).to eq("custom-class")
    end

    it "returns 'form-check form-check-inline' if options[:inline] is true" do
      allow(field).to receive(:options).and_return({ inline: true })
      expect(field.container_class).to eq("form-check form-check-inline")
    end

    it "returns 'form-check mb-2' by default" do
      allow(field).to receive(:options).and_return({})
      expect(field.container_class).to eq("form-check mb-2")
    end
  end

  describe "#data_attributes" do
    it "returns an empty hash by default" do
      expect(field.data_attributes).to eq({})
    end

    it "includes radio_toggle attributes when configured" do
      allow(field).to receive(:options).and_return({ stimulus: { radio_toggle: true } })
      expect(field.data_attributes).to include(
        search_form_target: "radioToggle",
        action: "change->search-form#toggleFromRadio"
      )
    end

    it "includes controls_select attributes when configured" do
      allow(field).to receive(:options).and_return({ stimulus: { controls_select: true } })
      expect(field.data_attributes).to include(controls_select: "true")
    end
  end

  describe "#radio_button_html_options" do
    it "builds a minimal set of options" do
      expected_options = {
        class: "form-check-input",
        checked: false,
        id: "form_test_radio_option1"
      }
      expect(field.radio_button_html_options).to eq(expected_options)
    end

    it "includes aria-describedby when help text is shown" do
      allow(field).to receive(:show_help_text?).and_return(true)
      expect(field.radio_button_html_options)
        .to include("aria-describedby": "form_test_radio_option1_help")
    end

    it "includes data attributes when they are present" do
      allow(field).to receive(:data_attributes).and_return({ custom: "value" })
      expect(field.radio_button_html_options).to include(data: { custom: "value" })
    end

    it "merges other options, excluding specific keys" do
      allow(field).to receive(:options).and_return({
                                                     inline: true,
                                                     container_class: "ignore-me",
                                                     stimulus: { radio_toggle: true },
                                                     disabled: true
                                                   })
      final_options = field.radio_button_html_options
      expect(final_options).to include(disabled: true)
      expect(final_options).not_to include(:inline, :container_class, :stimulus)
    end
  end
end
