require "rails_helper"

RSpec.describe(SearchForm::Fields::TagField, type: :component) do
  let(:form_state_double) { instance_double(SearchForm::Services::FormState) }
  let(:minimal_args) { { form_state: form_state_double } }

  subject(:field) { described_class.new(**minimal_args) }

  describe "#initialize" do
    it "assigns the form_state" do
      expect(field.instance_variable_get(:@form_state)).to eq(form_state_double)
    end

    it "stores additional options" do
      instance = described_class.new(**minimal_args, required: true)
      expect(instance.options).to eq({ required: true })
    end
  end

  describe "#setup_fields (via #before_render)" do
    let(:multi_select_double) { instance_double(SearchForm::Fields::Primitives::MultiSelectField, "multi_select") }
    let(:all_checkbox_double) { instance_double(SearchForm::Fields::Primitives::CheckboxField, "all_checkbox") }
    let(:or_radio_double) { instance_double(SearchForm::Fields::Primitives::RadioButtonField, "or_radio") }
    let(:and_radio_double) { instance_double(SearchForm::Fields::Primitives::RadioButtonField, "and_radio") }
    let(:checkbox_wrapper_double) { instance_double(SearchForm::Fields::Utilities::CheckboxGroupWrapper, "checkbox_wrapper") }
    let(:radio_wrapper_double) { instance_double(SearchForm::Fields::Utilities::RadioGroupWrapper, "radio_wrapper") }

    before do
      # The factory methods call `.with_form(form)`, which delegates to `form_state`.
      allow(form_state_double).to receive(:form)
      allow(form_state_double).to receive(:with_form)

      # Spy on the factory methods and wrappers to verify they are called correctly.
      allow(field).to receive(:create_multi_select_field).and_return(multi_select_double)
      allow(field).to receive(:create_all_checkbox).and_return(all_checkbox_double)
      allow(field).to receive(:create_radio_button_field).and_return(or_radio_double,
                                                                     and_radio_double)
      allow(SearchForm::Fields::Utilities::CheckboxGroupWrapper).to receive(:new)
        .and_return(checkbox_wrapper_double)
      allow(SearchForm::Fields::Utilities::RadioGroupWrapper).to receive(:new)
        .and_return(radio_wrapper_double)
    end

    it "calls create_multi_select_field with the correct arguments" do
      expected_args = {
        name: :tag_ids,
        label: I18n.t("basics.tags"),
        help_text: I18n.t("search.helpdesks.tag_field"),
        collection: [],
        data: field.send(:ajax_data_attributes)
      }
      expect(field).to receive(:create_multi_select_field).with(hash_including(expected_args))
      field.before_render
    end

    it "calls create_all_checkbox with the correct stimulus configuration" do
      expected_stimulus = { toggle: true, toggle_radio_group: "tag_operator",
                            default_radio_value: "or" }
      expect(field).to receive(:create_all_checkbox)
        .with(hash_including(for_field_name: :tag_ids, stimulus: expected_stimulus))
      field.before_render
    end

    it "calls create_radio_button_field for the 'OR' option" do
      expect(field).to receive(:create_radio_button_field)
        .with(hash_including(name: :tag_operator, value: "or", checked: true, disabled: true)).once
      field.before_render
    end

    it "calls create_radio_button_field for the 'AND' option" do
      expect(field).to receive(:create_radio_button_field)
        .with(hash_including(name: :tag_operator, value: "and", checked: false,
                             disabled: true)).once
      field.before_render
    end

    it "instantiates a CheckboxGroupWrapper and a RadioGroupWrapper" do
      expect(SearchForm::Fields::Utilities::CheckboxGroupWrapper).to receive(:new)
        .with(parent_field: multi_select_double, checkboxes: [all_checkbox_double])
      expect(SearchForm::Fields::Utilities::RadioGroupWrapper).to receive(:new)
        .with(name: :tag_operator, parent_field: multi_select_double, radio_buttons: [
                or_radio_double, and_radio_double
              ])
      field.before_render
    end

    it "passes through additional options to the multi-select field" do
      field_with_options = described_class.new(**minimal_args, required: true)
      allow(field_with_options).to receive(:create_multi_select_field)
        .and_return(multi_select_double)
      allow(field_with_options).to receive(:form_state).and_return(form_state_double)

      expect(field_with_options).to receive(:create_multi_select_field)
        .with(hash_including(required: true))

      field_with_options.before_render
    end
  end

  describe "#ajax_data_attributes (private)" do
    it "returns the correct hash for selectize/tom-select" do
      expected_data = {
        filled: false,
        ajax: true,
        model: "tag",
        locale: I18n.locale,
        placeholder: I18n.t("basics.select"),
        no_results: I18n.t("basics.no_results")
      }
      expect(field.send(:ajax_data_attributes)).to eq(expected_data)
    end
  end
end
