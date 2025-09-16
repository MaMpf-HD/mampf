require "rails_helper"

RSpec.describe(SearchForm::Fields::Primitives::SubmitField, type: :component) do
  let(:form_state_double) { instance_double(SearchForm::Services::FormState, "form_state") }
  let(:field_data_double) { instance_double(SearchForm::Fields::Services::FieldData, "field_data") }
  let(:minimal_args) { { form_state: form_state_double } }

  subject(:field) { described_class.new(**minimal_args) }

  # For most tests, stub the FieldData creation to isolate the component.
  before do
    allow(SearchForm::Fields::Services::FieldData).to receive(:new).and_return(field_data_double)
    allow(field_data_double).to receive(:define_singleton_method)
    allow(field_data_double).to receive(:extract_and_update_field_classes!)
  end

  describe "#initialize" do
    # For this specific test, we want to inspect the arguments passed to FieldData.new
    before do
      allow(SearchForm::Fields::Services::FieldData).to receive(:new).and_call_original
    end

    it "sets default classes" do
      expect(field.button_class).to eq("btn btn-primary")
      expect(field.inner_class).to eq("col-12 text-center")
    end

    it "allows overriding default classes" do
      instance = described_class.new(
        **minimal_args,
        button_class: "custom-btn",
        inner_class: "custom-inner"
      )
      expect(instance.button_class).to eq("custom-btn")
      expect(instance.inner_class).to eq("custom-inner")
    end

    context "when label is not provided" do
      it "uses the I18n default for the label" do
        allow(I18n).to receive(:t).with("basics.search").and_return("Default Search")
        described_class.new(**minimal_args)
      end
    end

    it "correctly passes all arguments to FieldData.new" do
      allow(I18n).to receive(:t).with("basics.search").and_return("Search")

      expect(SearchForm::Fields::Services::FieldData).to receive(:new)
        .with(hash_including(
                name: :submit,
                label: "Custom Label",
                form_state: form_state_double,
                help_text: nil,
                use_value_in_id: false,
                value: nil,
                options: hash_including("data-foo": "bar")
              ))

      described_class.new(
        form_state: form_state_double,
        label: "Custom Label",
        container_class: "custom-container",
        "data-foo": "bar"
      )
    end
  end

  describe "delegations" do
    it "delegates a limited set of methods to field_data" do
      expect(field_data_double).to receive(:name)
      field.name

      expect(field_data_double).to receive(:label)
      field.label

      expect(field_data_double).to receive(:form)
      field.form

      expect(field_data_double).to receive(:container_class)
      field.container_class

      expect(field_data_double).to receive(:form_state)
      field.form_state
    end
  end

  describe "#with_form" do
    it "delegates to the form_state object and returns self" do
      form_builder_double = instance_double(ActionView::Helpers::FormBuilder)
      allow(field_data_double).to receive(:form_state).and_return(form_state_double)
      expect(form_state_double).to receive(:with_form).with(form_builder_double)

      result = field.with_form(form_builder_double)
      expect(result).to be(field)
    end
  end
end
