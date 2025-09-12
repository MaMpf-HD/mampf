require "rails_helper"

RSpec.describe(SearchForm::Fields::Mixins::CompositeFieldMixin, type: :component) do
  # Create a dummy class that includes the mixin for isolated testing.
  let(:dummy_field_class) do
    Class.new do
      include SearchForm::Fields::Mixins::CompositeFieldMixin
    end
  end

  let(:form_state_double) { instance_double(SearchForm::Services::FormState, "form_state") }
  let(:form_builder_double) { instance_double(ActionView::Helpers::FormBuilder, "form_builder") }

  subject(:field_instance) { dummy_field_class.new }

  before do
    # Set up the form_state and form doubles for the instance.
    field_instance.form_state = form_state_double
    allow(form_state_double).to receive(:form).and_return(form_builder_double)
  end

  describe ".included" do
    it "adds a form_state accessor" do
      expect(field_instance).to respond_to(:form_state)
      expect(field_instance).to respond_to(:form_state=)
    end

    it "delegates :form to :form_state" do
      expect(form_state_double).to receive(:form)
      field_instance.form
    end
  end

  describe "#with_form" do
    it "calls with_form on the form_state object" do
      expect(form_state_double).to receive(:with_form).with(form_builder_double)
      field_instance.with_form(form_builder_double)
    end

    it "returns self for method chaining" do
      allow(form_state_double).to receive(:with_form)
      expect(field_instance.with_form(form_builder_double)).to be(field_instance)
    end
  end

  describe "#before_render" do
    it "calls the setup_fields method" do
      # The dummy class doesn't implement setup_fields, so we expect the NotImplementedError
      expect { field_instance.before_render }.to raise_error(NotImplementedError)
    end
  end

  describe "factory methods" do
    # Generic test for all factory methods
    shared_examples "a field factory" do |primitive_class, factory_method, config|
      let(:field_double) { instance_double(primitive_class, "field_double") }

      before do
        allow(primitive_class).to receive(:new).and_return(field_double)
        allow(field_double).to receive(:with_form).and_return(field_double)
      end

      it "instantiates the correct primitive field class" do
        expect(primitive_class).to receive(:new).with(form_state: form_state_double, **config)
        field_instance.send(factory_method, **config)
      end

      it "calls with_form on the new field" do
        expect(field_double).to receive(:with_form).with(form_builder_double)
        field_instance.send(factory_method, **config)
      end

      it "returns the configured field instance" do
        expect(field_instance.send(factory_method, **config)).to eq(field_double)
      end
    end

    describe "#create_multi_select_field" do
      include_examples "a field factory", SearchForm::Fields::Primitives::MultiSelectField,
                       :create_multi_select_field,
                       { name: :test, label: "Test", collection: [1, 2] }
    end

    describe "#create_text_field" do
      include_examples "a field factory", SearchForm::Fields::Primitives::TextField,
                       :create_text_field, { name: :test, label: "Test" }
    end

    describe "#create_select_field" do
      include_examples "a field factory", SearchForm::Fields::Primitives::SelectField,
                       :create_select_field, { name: :test, label: "Test", collection: [1, 2] }
    end

    describe "#create_radio_button_field" do
      include_examples "a field factory", SearchForm::Fields::Primitives::RadioButtonField,
                       :create_radio_button_field, { name: :test, label: "Test", value: "1" }
    end

    describe "#create_checkbox_field" do
      include_examples "a field factory", SearchForm::Fields::Primitives::CheckboxField,
                       :create_checkbox_field, { name: :test, label: "Test" }
    end

    describe "#create_all_checkbox" do
      let(:checkbox_double) { instance_double(SearchForm::Fields::Primitives::CheckboxField, "checkbox_double") }
      let(:config) { { for_field_name: :course_ids, stimulus: { toggle: true } } }

      before do
        allow(SearchForm::Fields::Primitives::CheckboxField).to receive(:new).and_return(checkbox_double)
        allow(checkbox_double).to receive(:with_form).and_return(checkbox_double)
      end

      it "instantiates a CheckboxField with generated and merged config" do
        expected_config = {
          name: :all_courses,
          label: I18n.t("basics.all"),
          checked: true,
          form_state: form_state_double,
          container_class: "form-check mb-2",
          stimulus: { toggle: true } # Merged from extra_config
        }
        expect(SearchForm::Fields::Primitives::CheckboxField).to receive(:new).with(**expected_config)
        field_instance.send(:create_all_checkbox, **config)
      end

      it "calls with_form on the new checkbox" do
        expect(checkbox_double).to receive(:with_form).with(form_builder_double)
        field_instance.send(:create_all_checkbox, **config)
      end
    end
  end

  describe "#setup_fields" do
    it "raises NotImplementedError by default" do
      expect do
        field_instance.send(:setup_fields)
      end.to raise_error(NotImplementedError, /must implement #setup_fields/)
    end
  end
end
