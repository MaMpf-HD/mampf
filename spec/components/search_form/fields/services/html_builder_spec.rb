require "rails_helper"

RSpec.describe(SearchForm::Fields::Services::HtmlBuilder, type: :component) do
  let(:field) { instance_double(SearchForm::Fields::Field, "field") }
  let(:form_state) { instance_double(SearchForm::Services::FormState, "form_state") }
  let(:css_manager) { instance_double(SearchForm::Fields::Services::CssManager, "css_manager") }

  subject(:builder) { described_class.new(field) }

  before do
    # Stub the instantiation of CssManager to return our mock.
    allow(SearchForm::Fields::Services::CssManager).to receive(:new)
      .with(field).and_return(css_manager)

    # Common stubs for the field and form_state doubles.
    allow(field).to receive(:form_state).and_return(form_state)
    allow(field).to receive(:name).and_return(:test_field)
    allow(form_state).to receive(:element_id_for).with(:test_field).and_return("test_field_id")
  end

  describe "#field_html_options" do
    before do
      # Set up base expectations for a standard field.
      allow(css_manager).to receive(:field_css_classes).and_return("form-control")
      allow(field).to receive(:options).and_return({})
      allow(field).to receive(:show_help_text?).and_return(false)
      allow(field).to receive(:is_a?).with(SearchForm::Fields::Primitives::SubmitField).and_return(false)
    end

    it "includes the id and class" do
      expected_options = {
        id: "test_field_id",
        class: "form-control"
      }
      expect(builder.field_html_options).to eq(expected_options)
    end

    it "merges additional options" do
      result = builder.field_html_options({ "data-foo": "bar" })
      expect(result).to include({ "data-foo": "bar" })
    end

    context "with accessibility attributes" do
      it "adds aria-describedby when help text is shown" do
        allow(field).to receive(:show_help_text?).and_return(true)
        expect(builder.field_html_options).to include({ "aria-describedby": "test_field_id_help" })
      end

      it "adds aria-required when the field is required" do
        allow(field).to receive(:options).and_return({ required: true })
        expect(builder.field_html_options).to include({ "aria-required": "true" })
      end

      it "adds aria-label for a SubmitField" do
        allow(field).to receive(:is_a?).with(SearchForm::Fields::Primitives::SubmitField).and_return(true)
        allow(field).to receive(:label).and_return("Search Button")
        expect(builder.field_html_options).to include({ "aria-label": "Search Button" })
      end
    end
  end

  describe "#select_tag_options" do
    before do
      # Default stubs for a non-selected field with no prompt.
      allow(field).to receive(:prompt).and_return(false)
      allow(field).to receive(:selected).and_return(nil)
    end

    it "returns an empty hash by default" do
      expect(builder.select_tag_options).to eq({})
    end

    context "with a prompt" do
      it "uses the default I18n text when prompt is true" do
        allow(field).to receive(:prompt).and_return(true)
        allow(I18n).to receive(:t).with("basics.select").and_return("Please select...")
        expect(builder.select_tag_options).to eq({ prompt: "Please select..." })
      end

      it "uses the provided string when prompt is a string" do
        allow(field).to receive(:prompt).and_return("Choose an option")
        expect(builder.select_tag_options).to eq({ prompt: "Choose an option" })
      end
    end

    context "with a selected value" do
      it "includes the selected value" do
        allow(field).to receive(:selected).and_return(5)
        expect(builder.select_tag_options).to eq({ selected: 5 })
      end
    end

    context "with both prompt and selected value" do
      it "includes both options" do
        allow(field).to receive(:prompt).and_return("Choose an option")
        allow(field).to receive(:selected).and_return(5)
        expect(builder.select_tag_options).to eq({ prompt: "Choose an option", selected: 5 })
      end
    end
  end

  describe "ID generation methods" do
    it "#element_id delegates to form_state" do
      expect(form_state).to receive(:element_id_for).with(:test_field)
      builder.element_id
    end

    it "#label_for delegates to form_state" do
      expect(form_state).to receive(:label_for).with(:test_field)
      builder.label_for
    end

    it "#help_text_id constructs the correct ID" do
      expect(builder.help_text_id).to eq("test_field_id_help")
    end
  end
end
