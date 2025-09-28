require "rails_helper"

RSpec.describe(SearchForm::Fields::Services::FieldData, type: :component) do
  let(:form_state_double) { instance_double(SearchForm::Services::FormState, "form_state") }
  let(:minimal_args) do
    {
      name: :test_field,
      label: "Test Field",
      form_state: form_state_double
    }
  end

  subject(:field_data) { described_class.new(**minimal_args) }

  describe "#initialize" do
    it "assigns core attributes correctly" do
      expect(field_data.name).to eq(:test_field)
      expect(field_data.label).to eq("Test Field")
      expect(field_data.form_state).to eq(form_state_double)
    end

    it "sets default values for layout options" do
      expect(field_data.container_class).to eq("col-6 col-lg-3 mb-3 form-field-group")
      expect(field_data.field_class).to eq("")
    end

    it "extracts layout options and stores remaining options" do
      options = { container_class: "custom-container", placeholder: "Enter text" }
      data = described_class.new(**minimal_args, options: options)

      expect(data.container_class).to eq("custom-container")
      expect(data.options).to eq({ placeholder: "Enter text" })
    end

    it "initializes CSS and HTML service objects" do
      expect(field_data.css).to be_a(SearchForm::Fields::Services::CssManager)
      expect(field_data.html).to be_a(SearchForm::Fields::Services::HtmlBuilder)
    end

    it "assigns all optional attributes" do
      all_args = minimal_args.merge(
        help_text: "Help",
        multiple: true,
        disabled: true,
        required: true,
        prompt: "Choose",
        selected: "value",
        value: "OR",
        use_value_in_id: true
      )
      data = described_class.new(**all_args)

      expect(data.help_text).to eq("Help")
      expect(data.multiple).to be(true)
      expect(data.disabled).to be(true)
      expect(data.required).to be(true)
      expect(data.prompt).to eq("Choose")
      expect(data.selected).to eq("value")
      expect(data.value).to eq("OR")
      expect(data.use_value_in_id).to be(true)
    end
  end

  describe "delegations" do
    let(:form_builder_double) { double("FormBuilder") }

    before do
      allow(form_state_double).to receive(:form).and_return(form_builder_double)
      allow(form_state_double).to receive(:context).and_return("test_context")
    end

    it "delegates :form to form_state" do
      expect(field_data.form).to eq(form_builder_double)
    end

    it "delegates :context to form_state" do
      expect(field_data.context).to eq("test_context")
    end
  end

  describe "#show_help_text?" do
    it "returns true when help_text is present" do
      data = described_class.new(**minimal_args, help_text: "Some help")
      expect(data.show_help_text?).to be(true)
    end

    it "returns false when help_text is nil" do
      expect(field_data.show_help_text?).to be(false)
    end

    it "returns false when help_text is an empty string" do
      data = described_class.new(**minimal_args, help_text: "")
      expect(data.show_help_text?).to be(false)
    end
  end

  describe "#with_content and #content" do
    it "stores and returns a content block" do
      content_proc = -> { "Block content" }
      field_data.with_content(&content_proc)
      expect(field_data.content).to eq(content_proc)
    end

    it "returns self for method chaining" do
      expect(field_data.with_content { nil }).to be(field_data)
    end

    it "#show_content? returns true after a block is added" do
      expect { field_data.with_content { nil } }.to change {
        field_data.show_content?
      }.from(false).to(true)
    end
  end

  describe "#default_field_classes" do
    it "returns an empty array by default" do
      expect(field_data.default_field_classes).to eq([])
    end
  end

  describe "#extract_and_update_field_classes!" do
    it "combines existing and new classes" do
      # Set an initial field_class
      field_data.field_class = "initial-class"

      # Mock the css manager to return a specific value
      allow(field_data.css).to receive(:extract_field_classes).with({ class: "user-class" })
                                                              .and_return("extracted-class")

      field_data.extract_and_update_field_classes!({ class: "user-class" })

      expect(field_data.field_class).to eq("initial-class extracted-class")
    end
  end

  describe "#before_render" do
    it "raises an error if form is not set" do
      allow(field_data).to receive(:form).and_return(nil)
      expect { field_data.before_render }.to raise_error(RuntimeError, /Form not set/)
    end

    it "does not raise an error if form is set" do
      allow(field_data).to receive(:form).and_return(double("FormBuilder"))
      expect { field_data.before_render }.not_to raise_error
    end
  end
end
