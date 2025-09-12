require "rails_helper"

RSpec.describe(SearchForm::Fields::Primitives::CheckboxField, type: :component) do
  let(:form_state_double) { instance_double(SearchForm::Services::FormState, "form_state") }
  let(:field_data_double) { instance_double(SearchForm::Fields::Services::FieldData, "field_data") }
  let(:minimal_args) do
    {
      name: :test_box,
      label: "Test Checkbox",
      form_state: form_state_double
    }
  end

  subject(:field) { described_class.new(**minimal_args) }

  before do
    # The mixin's initialize_field_data creates a FieldData object.
    # We stub this process to inject our double for isolated testing.
    allow(SearchForm::Fields::Services::FieldData).to receive(:new).and_return(field_data_double)
    allow(field_data_double).to receive(:define_singleton_method)
    allow(field_data_double).to receive(:extract_and_update_field_classes!)

    # Stub delegations from the mixin that are used by the component's methods.
    allow(field).to receive(:form_state).and_return(form_state_double)
    allow(field).to receive(:name).and_return(:test_box)
    allow(field).to receive(:options).and_return({})
    allow(field).to receive(:show_help_text?).and_return(false)

    # Stub ID generation methods that rely on form_state
    allow(form_state_double).to receive(:element_id_for).with(:test_box).and_return("form_test_box")
    allow(form_state_double).to receive(:label_for).with(:test_box)
                                                   .and_return("form_test_box_label")
  end

  describe "#initialize" do
    it "sets checked to false by default" do
      expect(field.checked).to be(false)
    end

    it "assigns the checked value when provided" do
      instance = described_class.new(**minimal_args, checked: true)
      expect(instance.checked).to be(true)
    end

    it "sets stimulus_config to an empty hash by default" do
      expect(field.stimulus_config).to eq({})
    end

    it "assigns the stimulus config when provided" do
      stimulus_options = { toggle: true }
      instance = described_class.new(**minimal_args, stimulus: stimulus_options)
      expect(instance.stimulus_config).to eq(stimulus_options)
    end

    it "calls initialize_field_data with empty default_classes" do
      expect(SearchForm::Fields::Services::FieldData).to receive(:new)
        .with(
          name: :test_box,
          label: "Test Checkbox",
          form_state: form_state_double,
          help_text: nil,
          options: {}
        )

      # Initialize the component to trigger the call.
      described_class.new(**minimal_args)
    end

    # Helper to create a dummy class for spying on the mixin's method call
    let(:dummy_field_class) do
      Class.new(described_class) do
        # Suppress original method
        def initialize_field_data(**)
        end
      end
    end
  end

  describe "#data_attributes" do
    context "with no stimulus config" do
      it "returns an empty hash" do
        expect(field.data_attributes).to eq({})
      end

      it "preserves other data attributes from options" do
        allow(field).to receive(:options).and_return({ data: { custom: "value" } })
        expect(field.data_attributes).to eq({ custom: "value" })
      end
    end

    context "with toggle stimulus config" do
      subject(:field) { described_class.new(**minimal_args, stimulus: { toggle: true }) }

      it "adds toggle attributes" do
        expected_data = {
          search_form_target: "allToggle",
          action: "change->search-form#toggleFromCheckbox"
        }
        expect(field.data_attributes).to eq(expected_data)
      end
    end

    context "with toggle_radio_group stimulus config" do
      let(:stimulus_config) { { toggle_radio_group: "group_name" } }
      subject(:field) { described_class.new(**minimal_args, stimulus: stimulus_config) }

      it "adds radio group toggle attributes" do
        expected_data = {
          action: "change->search-form#toggleRadioGroup",
          toggle_radio_group: "group_name"
        }
        expect(field.data_attributes).to eq(expected_data)
      end

      it "includes default_radio_value when provided" do
        stimulus_config[:default_radio_value] = "default_val"
        expect(field.data_attributes).to include(default_radio_value: "default_val")
      end
    end

    context "with both toggle and toggle_radio_group stimulus config" do
      let(:stimulus_config) { { toggle: true, toggle_radio_group: "group_name" } }
      subject(:field) { described_class.new(**minimal_args, stimulus: stimulus_config) }

      it "combines the actions" do
        expect(field.data_attributes[:action]).to eq(
          "change->search-form#toggleFromCheckbox change->search-form#toggleRadioGroup"
        )
      end
    end
  end

  describe "#checkbox_html_options" do
    it "builds a minimal set of options" do
      expected_options = {
        class: "form-check-input",
        checked: false,
        id: "form_test_box"
      }
      expect(field.checkbox_html_options).to eq(expected_options)
    end

    it "includes aria-describedby when help text is shown" do
      allow(field).to receive(:show_help_text?).and_return(true)
      expect(field.checkbox_html_options).to include("aria-describedby": "form_test_box_help")
    end

    it "includes data attributes when they are present" do
      allow(field).to receive(:data_attributes).and_return({ custom: "value" })
      expect(field.checkbox_html_options).to include(data: { custom: "value" })
    end

    it "merges other options, excluding container_class and data" do
      allow(field).to receive(:options).and_return({
                                                     container_class: "ignore-me",
                                                     data: { "original-data": "value" },
                                                     disabled: true
                                                   })
      # Stub the result of the specialized `data_attributes` method.
      # This simulates it having processed `options[:data]` and added its own attributes.
      allow(field).to receive(:data_attributes).and_return({
                                                             "original-data": "value",
                                                             "stimulus-data": "added"
                                                           })

      final_options = field.checkbox_html_options
      expect(final_options[:data]).to eq({
                                           "original-data": "value",
                                           "stimulus-data": "added"
                                         })
      expect(final_options).to include(disabled: true)
      expect(final_options).not_to include(:container_class)
    end
  end
end
