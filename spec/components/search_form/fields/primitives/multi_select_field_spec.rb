require "rails_helper"

RSpec.describe(SearchForm::Fields::Primitives::MultiSelectField, type: :component) do
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

  # For most tests, we stub the FieldData creation to isolate the component.
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

    it "initializes FieldData with processed options and default classes" do
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
                  multiple: true,
                  disabled: true,
                  required: true,
                  prompt: true
                )
              ))

      described_class.new(**minimal_args)
    end

    it "preserves user-provided options over defaults" do
      expect(SearchForm::Fields::Services::FieldData).to receive(:new)
        .with(hash_including(
                options: hash_including(
                  multiple: false,
                  prompt: "Select one..."
                )
              ))

      described_class.new(**minimal_args, multiple: false, prompt: "Select one...")
    end
  end

  describe "delegations" do
    it "delegates select-related methods to field_data" do
      expect(field_data_double).to receive(:multiple)
      field.multiple
    end

    it "delegates html builder methods to the html builder" do
      expect(html_builder_double).to receive(:select_tag_options)
      field.select_tag_options
    end
  end

  describe "#field_html_options" do
    it "merges data attributes from the builder with other options" do
      allow(field).to receive(:build_select_data_attributes).and_return({ custom: "data" })
      expect(html_builder_double).to receive(:field_html_options)
        .with({ data: { custom: "data" } })

      field.field_html_options
    end
  end

  describe "private methods" do
    describe "#process_options" do
      it "merges default values for a multi-select field" do
        processed = field.send(:process_options, {})
        expect(processed).to eq({
                                  multiple: true,
                                  disabled: true,
                                  required: true,
                                  prompt: true
                                })
      end
    end

    describe "#build_select_data_attributes" do
      it "adds the search_form_target" do
        allow(field_data_double).to receive(:options).and_return({})
        expect(field.send(:build_select_data_attributes)).to eq({ search_form_target: "select" })
      end

      it "preserves existing data attributes" do
        allow(field_data_double).to receive(:options).and_return({ data: { foo: "bar" } })
        expect(field.send(:build_select_data_attributes)).to eq({
                                                                  foo: "bar",
                                                                  search_form_target: "select"
                                                                })
      end
    end
  end
end
