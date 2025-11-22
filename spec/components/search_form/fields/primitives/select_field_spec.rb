require "rails_helper"

RSpec.describe(SearchForm::Fields::Primitives::SelectField, type: :component) do
  let(:form_state_double) { instance_double(SearchForm::Services::FormState, "form_state") }
  let(:field_data_double) { instance_double(SearchForm::Fields::Services::FieldData, "field_data") }
  let(:html_builder_double) { instance_double(SearchForm::Fields::Services::HtmlBuilder, "html_builder") }
  let(:minimal_args) do
    {
      name: :test_select,
      label: "Test Select",
      collection: [["Option 1", 1]],
      form_state: form_state_double
    }
  end

  subject(:field) { described_class.new(**minimal_args) }

  # For most tests, stub the FieldData creation to isolate the component.
  before do
    allow(SearchForm::Fields::Services::FieldData).to receive(:new).and_return(field_data_double)
    allow(field_data_double).to receive(:define_singleton_method)
    allow(field_data_double).to receive(:extract_and_update_field_classes!)
    allow(field_data_double).to receive(:html).and_return(html_builder_double)
  end

  describe "#initialize" do
    # For this specific test, we want to inspect the arguments passed to FieldData.new
    before do
      allow(SearchForm::Fields::Services::FieldData).to receive(:new).and_call_original
    end

    it "initializes FieldData with processed options" do
      # Use hash_including since the mixin converts keyword args to hash
      expect(SearchForm::Fields::Services::FieldData).to receive(:new)
        .with(hash_including(
                name: :test_select,
                label: "Test Select",
                form_state: form_state_double,
                help_text: nil,
                use_value_in_id: false,  # New parameter
                value: nil,              # New parameter
                options: hash_including(
                  prompt: false,         # Default from process_select_options
                  selected: nil
                )
              ))

      described_class.new(**minimal_args)
    end

    it "preserves user-provided options over defaults" do
      # Use hash_including for flexibility
      expect(SearchForm::Fields::Services::FieldData).to receive(:new)
        .with(hash_including(
                options: hash_including(
                  prompt: "Choose...",
                  selected: 5
                )
              ))

      described_class.new(**minimal_args, prompt: "Choose...", selected: 5)
    end
  end

  describe "delegations" do
    it "delegates html, prompt, and selected to field_data" do
      expect(field_data_double).to receive(:html)
      field.html

      expect(field_data_double).to receive(:prompt)
      field.prompt

      expect(field_data_double).to receive(:selected)
      field.selected
    end

    it "delegates select_tag_options to the html builder" do
      expect(html_builder_double).to receive(:select_tag_options)
      field.select_tag_options
    end
  end

  describe "private methods" do
    describe "#process_select_options" do
      it "merges the default value for prompt" do
        processed = field.send(:process_select_options, {})
        expect(processed).to eq({ prompt: false })
      end

      it "does not override a user-provided prompt" do
        processed = field.send(:process_select_options, { prompt: "Select One" })
        expect(processed).to eq({ prompt: "Select One" })
      end
    end
  end
end
