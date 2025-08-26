require "rails_helper"

RSpec.describe(SearchForm::Fields::Field, type: :component) do
  # A concrete implementation of the abstract Field for testing purposes.
  # We define it as a constant on the described class itself for stable access,
  # only if it hasn't been defined already.
  unless described_class.const_defined?("TestField")
    described_class.const_set(:TestField, Class.new(described_class) do
      attr_reader :css, :html
    end)
  end

  # Reference the constant explicitly from the described_class.
  let(:test_field_class) { described_class.const_get("TestField") }
  let(:name) { :query }
  let(:label) { "Search Term" }
  let(:options) { {} }
  let(:form_state) { instance_double(SearchForm::Services::FormState) }

  subject(:field) do
    field_instance = test_field_class.new(name: name, label: label, **options)
    field_instance.form_state = form_state # Manually set for testing
    field_instance
  end

  # ... (the rest of the spec file remains the same)
  describe "#initialize" do
    it "assigns name and label" do
      expect(field.name).to eq(:query)
      expect(field.label).to eq("Search Term")
    end

    it "initializes CssManager and HtmlBuilder services" do
      expect(field.css).to be_a(SearchForm::Fields::Services::CssManager)
      expect(field.html).to be_a(SearchForm::Fields::Services::HtmlBuilder)
    end

    context "with default options" do
      it "sets default container_class" do
        expect(field.container_class).to eq("col-6 col-lg-3 mb-3 form-field-group")
      end

      it "sets default field_class to empty string" do
        expect(field.field_class).to eq("")
      end

      it "sets help_text to nil" do
        expect(field.help_text).to be_nil
      end

      it "sets prompt using default_prompt hook" do
        expect(field.prompt).to be(false)
      end
    end

    context "with custom options" do
      let(:options) do
        {
          container_class: "custom-container",
          field_class: "custom-field",
          help_text: "Enter your query",
          prompt: "Select one...",
          placeholder: "e.g., Rails"
        }
      end

      it "assigns custom container_class" do
        expect(field.container_class).to eq("custom-container")
      end

      it "assigns custom field_class" do
        expect(field.field_class).to eq("custom-field")
      end

      it "assigns custom help_text" do
        expect(field.help_text).to eq("Enter your query")
      end

      it "assigns custom prompt" do
        expect(field.prompt).to eq("Select one...")
      end

      it "keeps unhandled options in the options hash" do
        expect(field.options).to eq({ placeholder: "e.g., Rails" })
      end
    end
  end

  describe "delegation" do
    it "delegates #form to form_state" do
      expect(form_state).to receive(:form)
      field.form
    end

    it "delegates #context to form_state" do
      expect(form_state).to receive(:context)
      field.context
    end
  end

  describe "#with_form" do
    let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

    it "calls with_form on the form_state object" do
      expect(form_state).to receive(:with_form).with(form_builder)
      field.with_form(form_builder)
    end

    it "returns self for chaining" do
      allow(form_state).to receive(:with_form)
      expect(field.with_form(form_builder)).to be(field)
    end
  end

  describe "#with_content" do
    it "assigns a given block to #content" do
      block = proc { "Hello" }
      field.with_content(&block)
      expect(field.content).to be(block)
    end

    it "returns self for chaining" do
      expect(field.with_content).to be(field)
    end
  end

  describe "helper methods" do
    it "#show_help_text? is true when help_text is present" do
      field_with_help = test_field_class.new(name: :q, label: "L", help_text: "Help")
      expect(field_with_help.show_help_text?).to be(true)
    end

    it "#show_help_text? is false when help_text is absent" do
      expect(field.show_help_text?).to be(false)
    end

    it "#show_content? is true when content is present" do
      field.with_content { "Hello" }
      expect(field.show_content?).to be(true)
    end

    it "#show_content? is false when content is absent" do
      expect(field.show_content?).to be(false)
    end
  end

  describe "#before_render hook" do
    let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

    it "raises an error when called without a form" do
      # Simulate the state where with_form was not called by using a real FormState
      field.form_state = SearchForm::Services::FormState.new
      expect { field.before_render }.to raise_error(/Form not set/)
    end

    it "does not raise an error when called with a form" do
      # Simulate the state where with_form was called by mocking the #form method
      allow(form_state).to receive(:form).and_return(instance_double(ActionView::Helpers::FormBuilder))
      expect { field.before_render }.not_to raise_error
    end
  end

  describe "subclass hooks" do
    it "#default_field_classes returns an empty array" do
      expect(field.default_field_classes).to eq([])
    end

    it "#selected returns the value from the options hash" do
      options[:selected] = "abc"
      expect(field.selected).to eq("abc")
    end

    it "#default_prompt returns false" do
      expect(field.default_prompt).to be(false)
    end
  end

  describe "#extract_and_update_field_classes!" do
    let(:options) { { class: "user-class" } }

    it "merges classes from options into field_class" do
      # Define a specific subclass for this test case to avoid side-effects
      class_with_hook = Class.new(test_field_class) do
        def initialize(name:, label:, **options)
          super
          extract_and_update_field_classes!(options)
        end

        def default_field_classes
          ["default-class"]
        end
      end

      field_instance = class_with_hook.new(name: :q, label: "L", **options)
      expect(field_instance.field_class).to eq("default-class user-class")
    end
  end
end
