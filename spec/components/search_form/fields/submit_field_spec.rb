require "rails_helper"

RSpec.describe(SearchForm::Fields::SubmitField, type: :component) do
  let(:label) { nil }
  let(:button_class) { nil }
  let(:container_class) { nil }
  let(:inner_class) { nil }
  let(:form_state) { instance_double(SearchForm::Services::FormState) }

  subject(:field) do
    # Build arguments hash, compacting to remove nils for default tests
    args = {
      label: label,
      button_class: button_class,
      container_class: container_class,
      inner_class: inner_class
    }.compact

    field_instance = described_class.new(**args)
    field_instance.form_state = form_state
    field_instance
  end

  describe "#initialize" do
    context "with default values" do
      it "sets the default label from I18n" do
        allow(I18n).to receive(:t).with("basics.search").and_return("Search Now")
        expect(field.label).to eq("Search Now")
      end

      it "sets the default button_class" do
        expect(field.button_class).to eq("btn btn-primary")
      end

      it "sets the default container_class" do
        expect(field.container_class).to eq("row mb-3")
      end

      it "sets the default inner_class" do
        expect(field.inner_class).to eq("col-12 text-center")
      end

      it "sets the name to :submit" do
        expect(field.name).to eq(:submit)
      end
    end

    context "with custom values" do
      let(:label) { "Find" }
      let(:button_class) { "my-button" }
      let(:container_class) { "my-container" }
      let(:inner_class) { "my-inner" }

      it "assigns the custom label" do
        expect(field.label).to eq("Find")
      end

      it "assigns the custom button_class" do
        expect(field.button_class).to eq("my-button")
      end

      it "assigns the custom container_class" do
        expect(field.container_class).to eq("my-container")
      end

      it "assigns the custom inner_class" do
        expect(field.inner_class).to eq("my-inner")
      end
    end
  end

  describe "rendering" do
    let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }
    let(:label) { "Go" }
    let(:button_class) { "search-btn" }
    let(:container_class) { "submit-container" }
    let(:inner_class) { "submit-inner" }

    before do
      allow(form_state).to receive(:form).and_return(form_builder)
      allow(form_state).to receive(:with_form).and_return(form_state)

      # Mock the call to form.submit
      allow(form_builder).to receive(:submit)
        .with("Go", class: "search-btn")
        .and_return('<input type="submit" value="Go" class="search-btn">'.html_safe)
    end

    it "renders the submit button inside its wrappers" do
      doc = Nokogiri::HTML(render_inline(field).to_s)

      # Check for wrappers
      container_node = doc.css("div.submit-container")
      expect(container_node.size).to eq(1)

      inner_node = container_node.css("div.submit-inner")
      expect(inner_node.size).to eq(1)

      # Check for the submit button itself
      button_node = inner_node.css('input[type="submit"].search-btn')
      expect(button_node.size).to eq(1)
      expect(button_node.attr("value").value).to eq("Go")
    end

    it "calls form.submit with the correct arguments" do
      expect(form_builder).to receive(:submit).with("Go", class: "search-btn")
      render_inline(field)
    end
  end
end
