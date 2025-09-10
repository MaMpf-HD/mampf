require "rails_helper"

RSpec.describe(SearchForm::Fields::Primitives::MultiSelectField, type: :component) do
  let(:name) { :tag_ids }
  let(:label) { "Tags" }
  let(:collection) { [["Tag 1", 1], ["Tag 2", 2]] }
  let(:options) { {} }
  let(:form_state) { instance_double(SearchForm::Services::FormState) }

  # Mock service objects to isolate the field's logic
  let(:checkbox_manager) { instance_double(SearchForm::Fields::Services::CheckboxManager) }
  let(:data_builder) { instance_double(SearchForm::Fields::Services::DataAttributesBuilder) }
  let(:html_builder) { instance_double(SearchForm::Fields::Services::HtmlBuilder) }

  before do
    # Allow the services to be instantiated with the field instance.
    allow(SearchForm::Fields::Services::CheckboxManager).to receive(:new)
      .and_return(checkbox_manager)
    allow(SearchForm::Fields::Services::DataAttributesBuilder).to receive(:new)
      .and_return(data_builder)
  end

  subject(:field) do
    field_instance = described_class.new(
      name: name,
      label: label,
      collection: collection,
      **options
    )
    field_instance.form_state = form_state
    # Manually inject the html_builder mock as it's created in the superclass
    field_instance.instance_variable_set(:@html, html_builder)
    field_instance
  end

  describe "#initialize" do
    it "assigns name, label, and collection" do
      expect(field.name).to eq(:tag_ids)
      expect(field.label).to eq("Tags")
      expect(field.collection).to eq(collection)
    end

    it "generates the correct all_toggle_name" do
      expect(field.all_toggle_name).to eq(:all_tags)
    end

    it "initializes its service objects" do
      # We must use a generic matcher here to avoid a circular dependency
      # where `with(field)` would trigger the subject before the expectation is set.
      expect(SearchForm::Fields::Services::CheckboxManager).to receive(:new)
        .with(an_instance_of(described_class)).and_return(checkbox_manager)
      expect(SearchForm::Fields::Services::DataAttributesBuilder).to receive(:new)
        .with(an_instance_of(described_class)).and_return(data_builder)
      field # trigger instantiation
    end

    context "with default options" do
      it "sets multiple to true" do
        expect(field.options[:multiple]).to be(true)
      end

      it "sets disabled to true" do
        expect(field.options[:disabled]).to be(true)
      end

      it "sets required to true" do
        expect(field.options[:required]).to be(true)
      end
    end

    context "with overridden options" do
      let(:options) { { disabled: false, required: false } }

      it "respects the user-provided value for disabled" do
        expect(field.options[:disabled]).to be(false)
      end

      it "respects the user-provided value for required" do
        expect(field.options[:required]).to be(false)
      end
    end
  end

  describe "#before_render" do
    before do
      # Mock the superclass call
      allow(form_state).to receive(:form).and_return(instance_double(ActionView::Helpers::FormBuilder))
    end

    it "calls setup_default_checkbox on the checkbox_manager" do
      expect(checkbox_manager).to receive(:setup_default_checkbox)
      field.before_render
    end

    context "when skip_all_checkbox? is true" do
      it "does not call setup_default_checkbox" do
        # Create an anonymous class with the hook method
        test_filter_class = Class.new(described_class) do
          def skip_all_checkbox?
            true
          end
        end
        # Use stub_const to safely define it for this test only.
        # This avoids the linter warning.
        stub_const("TestFilter", test_filter_class)

        test_field = TestFilter.new(name: name, label: label, collection: collection)
        test_field.form_state = form_state

        expect(checkbox_manager).not_to receive(:setup_default_checkbox)
        test_field.before_render
      end
    end
  end

  describe "helper methods and hooks" do
    it "#show_checkbox? delegates to checkbox_manager" do
      expect(checkbox_manager).to receive(:should_show_checkbox?).and_return(true)
      expect(field.show_checkbox?).to be(true)
    end

    it "#select_tag_options delegates to the html builder" do
      expect(html_builder).to receive(:select_tag_options)
      field.select_tag_options
    end

    it "#show_radio_group? returns false" do
      expect(field.show_radio_group?).to be(false)
    end

    it "#all_checkbox_label returns the correct translation" do
      expect(I18n).to receive(:t).with("basics.all").and_return("All")
      expect(field.all_checkbox_label).to eq("All")
    end

    it "#default_prompt returns true" do
      expect(field.default_prompt).to be(true)
    end

    it "#default_field_classes returns ['selectize']" do
      expect(field.default_field_classes).to eq(["selectize"])
    end
  end

  describe "#field_html_options" do
    it "merges data attributes from the data_builder" do
      select_data = { controller: "select" }
      base_options = { id: "field_id" }

      expect(data_builder).to receive(:select_data_attributes).and_return(select_data)
      expect(html_builder).to receive(:field_html_options)
        .with(hash_including(data: select_data))
        .and_return(base_options.merge(data: select_data))

      result = field.field_html_options
      expect(result).to eq({ id: "field_id", data: { controller: "select" } })
    end
  end
end
