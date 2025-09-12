require "rails_helper"

RSpec.describe(SearchForm::Fields::LectureTypeField, type: :component) do
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
    let(:multi_select_double) { instance_double(SearchForm::Fields::Primitives::MultiSelectField) }
    let(:checkbox_double) { instance_double(SearchForm::Fields::Primitives::CheckboxField) }
    let(:wrapper_double) { instance_double(SearchForm::Fields::Utilities::CheckboxGroupWrapper) }
    let(:lecture_types_collection) { [["Lecture", "lecture"], ["Seminar", "seminar"]] }

    before do
      # The factory methods call `.with_form(form)`, which delegates to `form_state`.
      allow(form_state_double).to receive(:form)
      allow(form_state_double).to receive(:with_form)

      # Spy on the factory methods and wrapper to verify they are called correctly.
      allow(field).to receive(:create_multi_select_field).and_return(multi_select_double)
      allow(field).to receive(:create_all_checkbox).and_return(checkbox_double)
      allow(SearchForm::Fields::Utilities::CheckboxGroupWrapper).to receive(:new)
        .and_return(wrapper_double)

      # Stub the class method that provides the collection data.
      allow(Lecture).to receive(:select_sorts).and_return(lecture_types_collection)
    end

    it "calls create_multi_select_field with the correct, hard-coded arguments" do
      expected_args = {
        name: :types,
        label: I18n.t("basics.type"),
        help_text: I18n.t("search.fields.helpdesks.lecture_type_field"),
        collection: lecture_types_collection
      }

      expect(field).to receive(:create_multi_select_field).with(hash_including(expected_args))

      # before_render is the public method that triggers the private setup_fields
      field.before_render
    end

    it "calls create_all_checkbox with the correct field name" do
      expect(field).to receive(:create_all_checkbox).with(for_field_name: :types)
      field.before_render
    end

    it "instantiates a CheckboxGroupWrapper with the created fields" do
      expect(SearchForm::Fields::Utilities::CheckboxGroupWrapper).to receive(:new)
        .with(
          parent_field: multi_select_double,
          checkboxes: [checkbox_double]
        )
      field.before_render
    end

    it "passes through additional options to the multi-select field" do
      field_with_options = described_class.new(**minimal_args, disabled: true)
      allow(field_with_options).to receive(:create_multi_select_field)
        .and_return(multi_select_double)
      allow(field_with_options).to receive(:form_state).and_return(form_state_double)

      expect(field_with_options).to receive(:create_multi_select_field)
        .with(hash_including(disabled: true))

      field_with_options.before_render
    end
  end
end
