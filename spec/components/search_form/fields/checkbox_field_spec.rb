require "rails_helper"

RSpec.describe(SearchForm::Fields::CheckboxField, type: :component) do
  let(:name) { :is_active }
  let(:label) { "Is Active" }
  let(:checked) { false }
  let(:options) { {} }
  let(:form_state) { instance_double(SearchForm::Services::FormState) }

  subject(:field) do
    field_instance = described_class.new(
      name: name,
      label: label,
      checked: checked,
      **options
    )
    field_instance.form_state = form_state
    field_instance
  end

  describe "#initialize" do
    it "assigns the name and label" do
      expect(field.name).to eq(:is_active)
      expect(field.label).to eq("Is Active")
    end

    it "assigns the checked state" do
      field_checked = described_class.new(name: name, label: label, checked: true)
      expect(field_checked.checked).to be(true)
    end

    it "defaults checked to false" do
      field_default = described_class.new(name: name, label: label)
      expect(field_default.checked).to be(false)
    end

    it "passes other options to the superclass" do
      custom_field = described_class.new(
        name: name,
        label: label,
        container_class: "custom-wrapper"
      )
      expect(custom_field.container_class).to eq("custom-wrapper")
    end
  end

  describe "#checkbox_control" do
    let(:checkbox_control_double) { instance_double(SearchForm::Controls::Checkbox) }

    before do
      allow(SearchForm::Controls::Checkbox).to receive(:new)
        .and_return(checkbox_control_double)
    end

    it "initializes a Controls::Checkbox with correct parameters" do
      expect(SearchForm::Controls::Checkbox).to receive(:new).with(
        form_state: form_state,
        name: :is_active,
        label: "Is Active",
        checked: false,
        container_class: "form-check mb-2"
      ).and_return(checkbox_control_double)

      field.checkbox_control
    end

    it "returns an instance of Controls::Checkbox" do
      expect(field.checkbox_control).to be(checkbox_control_double)
    end

    it "memoizes the result" do
      expect(SearchForm::Controls::Checkbox).to receive(:new)
        .once.and_return(checkbox_control_double)
      field.checkbox_control
      field.checkbox_control
    end
  end

  describe "#default_field_classes" do
    it "returns an empty array" do
      expect(field.default_field_classes).to eq([])
    end
  end

  describe "rendering" do
    let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

    before do
      # Set up the form state for rendering
      allow(form_state).to receive(:form).and_return(form_builder)
      allow(form_state).to receive(:with_form).and_return(form_state)

      # Mock the underlying Rails form helpers that the real Checkbox control would call
      allow(form_builder).to receive(:check_box)
        .and_return('<input type="checkbox" class="form-check-input">'.html_safe)
      allow(form_builder).to receive(:label)
        .and_return('<label class="form-check-label">Is Active</label>'.html_safe)

      # THIS IS THE FIX: Make the mocks more specific.
      # Mock the call from Controls::Checkbox
      allow(form_state).to receive(:element_id_for).with(:is_active).and_return("checkbox_id")
      # Mock the call from the template's html.help_text_id
      allow(form_state).to receive(:element_id_for).with(:is_active,
                                                         "help_text").and_return("help_text_id")

      allow(form_state).to receive(:label_for).and_return("some_id_label")
    end

    it "renders the underlying checkbox control inside its container" do
      # Parse the rendered HTML string with Nokogiri
      doc = Nokogiri::HTML(render_inline(field).to_s)

      # Check for the outer container div from the CheckboxField template
      expect(doc.css("div.col-6.col-lg-3.mb-3.form-field-group").size).to eq(1)

      # Check for the inner elements from the rendered Controls::Checkbox
      expect(doc.css('input[type="checkbox"].form-check-input').size).to eq(1)

      label_node = doc.css("label.form-check-label")
      expect(label_node.size).to eq(1)
      expect(label_node.text).to eq("Is Active")
    end
  end
end
