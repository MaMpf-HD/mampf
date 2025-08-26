# spec/components/search_form/fields/select_field_spec.rb
require "rails_helper"

RSpec.describe(SearchForm::Fields::SelectField, type: :component) do
  let(:name) { :category_id }
  let(:label) { "Category" }
  let(:collection) { [["Category A", 1], ["Category B", 2]] }
  let(:options) { {} }
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:html_builder) { instance_double(SearchForm::Fields::Services::HtmlBuilder) }

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
    it "assigns the name, label, and collection" do
      expect(field.name).to eq(:category_id)
      expect(field.label).to eq("Category")
      expect(field.collection).to eq(collection)
    end

    it "passes other options to the superclass" do
      custom_field = described_class.new(
        name: name,
        label: label,
        collection: collection,
        container_class: "custom-wrapper"
      )
      expect(custom_field.container_class).to eq("custom-wrapper")
    end

    it "defaults prompt to false" do
      expect(field.prompt).to be(false)
    end

    context "with a prompt option" do
      let(:options) { { prompt: "Please select" } }

      it "assigns the prompt" do
        expect(field.prompt).to eq("Please select")
      end
    end
  end

  describe "#select_tag_options" do
    it "delegates to the html builder" do
      expect(html_builder).to receive(:select_tag_options)
      field.select_tag_options
    end
  end

  describe "#default_field_classes" do
    it "returns ['form-select']" do
      expect(field.default_field_classes).to eq(["form-select"])
    end
  end
end
