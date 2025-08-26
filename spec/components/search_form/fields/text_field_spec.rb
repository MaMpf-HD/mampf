# spec/components/search_form/fields/text_field_spec.rb
require "rails_helper"

RSpec.describe(SearchForm::Fields::TextField, type: :component) do
  let(:name) { :query }
  let(:label) { "Search" }
  let(:options) { {} }
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:html_builder) { instance_double(SearchForm::Fields::Services::HtmlBuilder) }

  subject(:field) do
    field_instance = described_class.new(
      name: name,
      label: label,
      **options
    )
    field_instance.form_state = form_state
    # Manually inject the html_builder mock as it's created in the superclass
    field_instance.instance_variable_set(:@html, html_builder)
    field_instance
  end

  describe "#initialize" do
    it "assigns the name and label" do
      expect(field.name).to eq(:query)
      expect(field.label).to eq("Search")
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

  describe "#default_field_classes" do
    it "returns ['form-control']" do
      expect(field.default_field_classes).to eq(["form-control"])
    end
  end

  describe "rendering" do
    let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

    before do
      # Set up the form state for rendering
      allow(form_state).to receive(:form).and_return(form_builder)
      allow(form_state).to receive(:with_form).and_return(form_state)

      # Mock the calls made from the template
      allow(html_builder).to receive(:label_for).and_return("search_query_label")
      allow(html_builder).to receive(:field_html_options).and_return({ class: "form-control" })

      # Mock the underlying Rails form helpers
      allow(form_builder).to receive(:label)
        .and_return('<label for="search_query_label">Search</label>'.html_safe)
      allow(form_builder).to receive(:text_field)
        .and_return('<input type="text" class="form-control">'.html_safe)
    end

    it "renders a text input field with its label and container" do
      doc = Nokogiri::HTML(render_inline(field).to_s)

      # Check for the outer container div
      expect(doc.css("div.col-6.col-lg-3.mb-3.form-field-group").size).to eq(1)

      # Check for the label and text field
      expect(doc.css('label[for="search_query_label"]').text).to eq("Search")
      expect(doc.css('input[type="text"].form-control').size).to eq(1)
    end
  end
end
