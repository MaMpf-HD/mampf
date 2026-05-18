require "rails_helper"

RSpec.describe(SearchForm::Fields::Services::HtmlBuilder, type: :component) do
  let(:field_data) { instance_double(SearchForm::Fields::Services::FieldData, "field_data") }
  let(:form_state) { instance_double(SearchForm::Services::FormState, "form_state") }
  let(:css_manager) { instance_double(SearchForm::Fields::Services::CssManager, "css_manager") }

  subject(:builder) { described_class.new(field_data) }

  before do
    # Stub the instantiation of CssManager to return our mock.
    allow(SearchForm::Fields::Services::CssManager).to receive(:new)
      .with(field_data).and_return(css_manager)

    # Common stubs for the field_data and form_state doubles.
    allow(field_data).to receive(:form_state).and_return(form_state)
    allow(field_data).to receive(:name).and_return(:test_field)
    allow(form_state).to receive(:element_id_for).with(:test_field).and_return("test_field_id")
    allow(form_state).to receive(:label_for).with(:test_field).and_return("test_field_id_label")
  end

  describe "#field_html_options" do
    before do
      # Set up base expectations for a standard field.
      allow(css_manager).to receive(:field_css_classes).and_return("form-control")
      allow(field_data).to receive(:options).and_return({})
      allow(field_data).to receive(:show_help_text?).and_return(false)
      allow(field_data).to receive(:use_value_in_id).and_return(false)
      allow(field_data).to receive(:value).and_return(nil)
      # The method being stubbed is on the builder, not the field_data
      allow(builder).to receive(:html_options_with_id).and_wrap_original do |_method, *args|
        { id: "test_field_id" }.merge(*args)
      end
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
        allow(field_data).to receive(:show_help_text?).and_return(true)
        expect(builder.field_html_options).to include({ "aria-describedby": "test_field_id_help" })
      end

      it "adds aria-required when the field is required" do
        allow(field_data).to receive(:options).and_return({ required: true })
        expect(builder.field_html_options).to include({ "aria-required": "true" })
      end
    end
  end

  describe "#select_tag_options" do
    before do
      # Default stubs for a non-selected field with no prompt.
      allow(field_data).to receive(:prompt).and_return(false)
      allow(field_data).to receive(:selected).and_return(nil)
    end

    it "returns an empty hash by default" do
      expect(builder.select_tag_options).to eq({})
    end

    context "with a prompt" do
      it "uses the default I18n text when prompt is true" do
        allow(field_data).to receive(:prompt).and_return(true)
        allow(I18n).to receive(:t).with("basics.select").and_return("Please select...")
        expect(builder.select_tag_options).to eq({ prompt: "Please select..." })
      end

      it "uses the provided string when prompt is a string" do
        allow(field_data).to receive(:prompt).and_return("Choose an option")
        expect(builder.select_tag_options).to eq({ prompt: "Choose an option" })
      end
    end

    context "with a selected value" do
      it "includes the selected value" do
        allow(field_data).to receive(:selected).and_return(5)
        expect(builder.select_tag_options).to eq({ selected: 5 })
      end
    end

    context "with both prompt and selected value" do
      it "includes both options" do
        allow(field_data).to receive(:prompt).and_return("Choose an option")
        allow(field_data).to receive(:selected).and_return(5)
        expect(builder.select_tag_options).to eq({ prompt: "Choose an option", selected: 5 })
      end
    end
  end

  describe "ID generation methods with values" do
    context "when use_value_in_id is false" do
      before do
        allow(field_data).to receive(:use_value_in_id).and_return(false)
        allow(field_data).to receive(:value).and_return("some_value")
      end

      it "#element_id does not include value" do
        expect(form_state).to receive(:element_id_for).with(:test_field)
        builder.element_id
      end

      it "#label_for does not include value" do
        expect(form_state).to receive(:label_for).with(:test_field)
        builder.label_for
      end
    end

    context "when use_value_in_id is true" do
      before do
        allow(field_data).to receive(:use_value_in_id).and_return(true)
      end

      context "with a present value" do
        before do
          allow(field_data).to receive(:value).and_return("option_a")
        end

        it "#element_id includes the value" do
          expect(form_state).to receive(:element_id_for).with(:test_field, "option_a")
          builder.element_id
        end

        it "#label_for includes the value" do
          expect(form_state).to receive(:label_for).with(:test_field, "option_a")
          builder.label_for
        end
      end

      context "with a blank value" do
        before do
          allow(field_data).to receive(:value).and_return("")
        end

        it "#element_id does not include blank value" do
          expect(form_state).to receive(:element_id_for).with(:test_field)
          builder.element_id
        end

        it "#label_for does not include blank value" do
          expect(form_state).to receive(:label_for).with(:test_field)
          builder.label_for
        end
      end

      context "with a nil value" do
        before do
          allow(field_data).to receive(:value).and_return(nil)
        end

        it "#element_id does not include nil value" do
          expect(form_state).to receive(:element_id_for).with(:test_field)
          builder.element_id
        end

        it "#label_for does not include nil value" do
          expect(form_state).to receive(:label_for).with(:test_field)
          builder.label_for
        end
      end
    end

    context "#help_text_id with value-based IDs" do
      before do
        allow(field_data).to receive(:use_value_in_id).and_return(true)
        allow(field_data).to receive(:value).and_return("option_b")
        allow(form_state).to receive(:element_id_for).with(:test_field, "option_b")
                                                     .and_return("test_field_option_b_id")
      end

      it "constructs help text ID from value-based element ID" do
        expect(builder.help_text_id).to eq("test_field_option_b_id_help")
      end
    end
  end
end
