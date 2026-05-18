require "rails_helper"

RSpec.describe(SearchForm::Fields::EditorField, type: :component) do
  let(:form_state_double) { instance_double(SearchForm::Services::FormState) }
  let(:minimal_args) { { form_state: form_state_double } }

  subject(:field) { described_class.new(**minimal_args) }

  describe "#initialize" do
    it "assigns the form_state" do
      expect(field.form_state).to eq(form_state_double)
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

    before do
      # The factory methods call `.with_form(form)`, which delegates `form` to `form_state`.
      allow(form_state_double).to receive(:form)

      # Spy on the factory methods and wrapper to verify they are called correctly.
      allow(field).to receive(:create_multi_select_field).and_return(multi_select_double)
      allow(field).to receive(:create_all_checkbox).and_return(checkbox_double)
      allow(SearchForm::Fields::Utilities::CheckboxGroupWrapper).to receive(:new)
        .and_return(wrapper_double)

      # Stub the private method that hits the DB to keep this test focused on composition.
      allow(field).to receive(:editor_options).and_return([["Editor A", 1]])
    end

    it "calls create_multi_select_field with the correct, hard-coded arguments" do
      expected_args = {
        name: :editor_ids,
        label: I18n.t("basics.editors"),
        help_text: I18n.t("search.helpdesks.editor_field"),
        collection: [["Editor A", 1]]
      }

      expect(field).to receive(:create_multi_select_field).with(hash_including(expected_args))

      # before_render is the public method that triggers the private setup_fields
      field.before_render
    end

    it "calls create_all_checkbox with the correct field name" do
      expect(field).to receive(:create_all_checkbox).with(for_field_name: :editor_ids)
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
      allow(field_with_options).to receive(:create_all_checkbox).and_return(checkbox_double)
      allow(field_with_options).to receive(:form_state).and_return(form_state_double)
      allow(form_state_double).to receive(:form)
      allow(form_state_double).to receive(:with_form)

      expect(field_with_options).to receive(:create_multi_select_field)
        .with(hash_including(disabled: true))

      field_with_options.before_render
    end
  end

  describe "#editor_options (private)" do
    let!(:editor_b) do
      create(:confirmed_user, name: "Zebra", name_in_tutorials: "Editor B", email: "b@m.com")
    end
    let!(:editor_a) { create(:confirmed_user, name: "Editor A", email: "a@m.com") }
    let!(:non_editor) { create(:confirmed_user, name: "Non-Editor") }
    let!(:course) { create(:course) }

    before do
      create(:editable_user_join, editable: course, user: editor_a)
      create(:editable_user_join, editable: course, user: editor_b)
    end

    it "returns a sorted list of editors with correctly formatted names" do
      expected_collection = [
        ["Editor A (a@m.com)", editor_a.id],
        ["Editor B (b@m.com)", editor_b.id]
      ]

      # Call the private method using .send
      expect(field.send(:editor_options)).to eq(expected_collection)
    end
  end
end
