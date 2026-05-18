require "rails_helper"

RSpec.describe(SearchForm::Fields::Primitives::TextField, type: :component) do
  let(:form_state_double) { instance_double(SearchForm::Services::FormState, "form_state") }
  let(:field_data_double) { instance_double(SearchForm::Fields::Services::FieldData, "field_data") }
  let(:minimal_args) do
    {
      name: :test_field,
      label: "Test Field",
      form_state: form_state_double
    }
  end

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

    it "correctly passes minimal arguments to FieldData.new" do
      # Updated expectation to include the new parameters
      expect(SearchForm::Fields::Services::FieldData).to receive(:new)
        .with(
          name: :test_field,
          label: "Test Field",
          form_state: form_state_double,
          help_text: nil,
          options: {},
          use_value_in_id: false,  # New parameter
          value: nil               # New parameter
        )

      described_class.new(**minimal_args)
    end

    it "correctly passes additional options to FieldData.new" do
      # Updated expectation to include the new parameters
      expect(SearchForm::Fields::Services::FieldData).to receive(:new)
        .with(hash_including(
                help_text: "Some help",
                use_value_in_id: false,  # New parameter
                value: nil,              # New parameter
                options: hash_including(
                  help_text: "Some help",
                  placeholder: "Enter text...",
                  required: true
                )
              ))

      described_class.new(
        **minimal_args,
        help_text: "Some help",
        placeholder: "Enter text...",
        required: true
      )
    end
  end

  describe "delegations" do
    it "delegates :html to the field_data object" do
      html_builder_double = instance_double(SearchForm::Fields::Services::HtmlBuilder)
      allow(field_data_double).to receive(:html).and_return(html_builder_double)

      expect(field.html).to be(html_builder_double)
    end
  end
end
