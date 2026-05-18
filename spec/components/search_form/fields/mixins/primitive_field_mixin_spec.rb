require "rails_helper"

RSpec.describe(SearchForm::Fields::Mixins::PrimitiveFieldMixin, type: :component) do
  # Create a dummy class that includes the mixin for isolated testing.
  let(:dummy_field_class) do
    Class.new do
      include SearchForm::Fields::Mixins::PrimitiveFieldMixin

      attr_reader :field_data # Expose for inspection
    end
  end

  let(:form_state_double) { instance_double(SearchForm::Services::FormState, "form_state") }
  let(:field_data_double) { instance_double(SearchForm::Fields::Services::FieldData, "field_data") }
  let(:form_builder_double) { instance_double(ActionView::Helpers::FormBuilder, "form_builder") }

  subject(:field_instance) { dummy_field_class.new }

  describe ".included" do
    it "delegates common methods to field_data" do
      # Assign the double to the instance variable the mixin expects
      field_instance.instance_variable_set(:@field_data, field_data_double)

      # Test a few key delegations
      expect(field_data_double).to receive(:name)
      field_instance.name

      expect(field_data_double).to receive(:form)
      field_instance.form

      expect(field_data_double).to receive(:options)
      field_instance.options
    end
  end

  describe "#initialize_field_data" do
    let(:options) { { help_text: "Help me", class: "custom-class" } }

    before do
      # Stub the FieldData constructor and the methods called within initialize_field_data
      allow(SearchForm::Fields::Services::FieldData).to receive(:new).and_return(field_data_double)
      allow(field_data_double).to receive(:define_singleton_method)
      allow(field_data_double).to receive(:extract_and_update_field_classes!)
    end

    it "initializes a FieldData object with correct parameters" do
      expect(SearchForm::Fields::Services::FieldData).to receive(:new).with(
        name: :test_field,
        label: "Test Label",
        help_text: "Help me",
        form_state: form_state_double,
        value: nil, # New parameter with default value
        use_value_in_id: false, # New parameter with default value
        options: { class: "custom-class", help_text: "Help me" } # help_text remains in options
      )

      field_instance.initialize_field_data(
        name: :test_field,
        label: "Test Label",
        form_state: form_state_double,
        **options
      )

      expect(field_instance.field_data).to be(field_data_double)
    end

    it "passes custom value and use_value_in_id parameters when provided" do
      expect(SearchForm::Fields::Services::FieldData).to receive(:new).with(
        name: :test_field,
        label: "Test Label",
        help_text: "Help me",
        form_state: form_state_double,
        value: "custom_value",
        use_value_in_id: true,
        options: { class: "custom-class", help_text: "Help me" } # help_text remains in options
      )

      field_instance.initialize_field_data(
        name: :test_field,
        label: "Test Label",
        form_state: form_state_double,
        value: "custom_value",
        use_value_in_id: true,
        **options
      )
    end

    it "defines a singleton method for default_field_classes on the FieldData instance" do
      expect(field_data_double).to receive(:define_singleton_method).with(:default_field_classes)
      field_instance.initialize_field_data(name: :test, label: "Test",
                                           form_state: form_state_double,
                                           default_classes: ["form-control"])
    end

    it "calls extract_and_update_field_classes! on the FieldData instance" do
      expect(field_data_double).to receive(:extract_and_update_field_classes!).with(options)
      field_instance.initialize_field_data(name: :test, label: "Test",
                                           form_state: form_state_double, **options)
    end
  end

  describe "#form_state=" do
    it "delegates to the field_data object" do
      field_instance.instance_variable_set(:@field_data, field_data_double)
      new_form_state = instance_double(SearchForm::Services::FormState)

      expect(field_data_double).to receive(:form_state=).with(new_form_state)
      field_instance.form_state = new_form_state
    end
  end

  describe "#with_form" do
    before do
      allow(field_data_double).to receive(:form_state).and_return(form_state_double)
      field_instance.instance_variable_set(:@field_data, field_data_double)
    end

    it "calls with_form on the form_state object" do
      expect(form_state_double).to receive(:with_form).with(form_builder_double)
      field_instance.with_form(form_builder_double)
    end

    it "returns self for method chaining" do
      allow(form_state_double).to receive(:with_form)
      expect(field_instance.with_form(form_builder_double)).to be(field_instance)
    end
  end

  describe "#with_content" do
    before do
      field_instance.instance_variable_set(:@field_data, field_data_double)
    end

    it "delegates the content block to field_data" do
      content_block = -> { "content" }
      # Pass the block to `receive` directly, not to `with`
      expect(field_data_double).to receive(:with_content, &content_block)
      field_instance.with_content(&content_block)
    end

    it "returns self for method chaining" do
      allow(field_data_double).to receive(:with_content)
      expect(field_instance.with_content { nil }).to be(field_instance)
    end
  end

  describe "#before_render" do
    before do
      field_instance.instance_variable_set(:@field_data, field_data_double)
    end

    context "when form is not set" do
      it "raises a RuntimeError" do
        allow(field_data_double).to receive(:form).and_return(nil)
        expect { field_instance.before_render }.to raise_error(RuntimeError, /Form not set/)
      end
    end

    context "when form is set" do
      it "does not raise an error" do
        allow(field_data_double).to receive(:form).and_return(form_builder_double)
        expect { field_instance.before_render }.not_to raise_error
      end
    end
  end
end
