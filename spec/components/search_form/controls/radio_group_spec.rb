require "rails_helper"

RSpec.describe(SearchForm::Controls::RadioGroup, type: :component) do
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:name) { :operator }
  let(:options) { {} }

  subject(:group) do
    described_class.new(
      form_state: form_state,
      name: name,
      **options
    )
  end

  describe "#initialize" do
    it "assigns the name" do
      expect(group.name).to eq(name)
    end

    it "correctly passes options to the superclass" do
      expect(group.form_state).to eq(form_state)
    end
  end

  describe "#add_radio_button" do
    it "calls with_radio_button with the correct arguments" do
      # Spy on the underlying ViewComponent method
      expect(group).to receive(:with_radio_button).with(
        form_state: form_state,
        name: name,
        value: "AND",
        label: "And",
        checked: true
      )

      group.add_radio_button(value: "AND", label: "And", checked: true)
    end

    it "forwards a block if given" do
      block = proc {}
      expect(group).to receive(:with_radio_button).with(hash_including(value: "OR"), &block)
      group.add_radio_button(value: "OR", &block)
    end
  end

  describe "#default_container_class" do
    it "returns the correct default class" do
      expect(group.default_container_class).to eq("mt-2")
    end
  end

  describe "ID generation" do
    it "uses its name for the ID parts" do
      expect(form_state).to receive(:element_id_for).with(name)
      group.element_id
    end
  end

  describe "rendering" do
    let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

    before do
      # Mock the form_state methods that will be called during render
      allow(form_state).to receive(:with_form).and_return(form_state)
      allow(form_state).to receive(:form).and_return(form_builder)

      # Mock calls for the first radio button
      allow(form_state).to receive(:label_for).with(:operator, "AND").and_return("op_and_label")
      allow(form_state).to receive(:element_id_for).with(:operator, "AND").and_return("op_and_id")

      # Mock calls for the second radio button
      allow(form_state).to receive(:label_for).with(:operator, "OR").and_return("op_or_label")
      allow(form_state).to receive(:element_id_for).with(:operator, "OR").and_return("op_or_id")

      # Mock the form_builder methods
      allow(form_builder).to receive(:radio_button) {
        '<input type="radio" class="form-check-input">'.html_safe
      }
      allow(form_builder).to receive(:label) {
        '<label class="form-check-label"></label>'.html_safe
      }
    end

    it "renders an empty div if no radio buttons are added" do
      rendered = render_inline(group)
      expect(rendered.css("div.mt-2").inner_html.strip).to be_empty
    end

    it "renders the radio buttons that have been added" do
      # This is the correct pattern: add the slots inside the render block.
      rendered = render_inline(group) do |g|
        g.add_radio_button(value: "AND", label: "And")
        g.add_radio_button(value: "OR", label: "Or")
      end

      # Check that two radio buttons are rendered inside the group
      expect(rendered.css(".form-check-input").count).to eq(2)
      expect(rendered.css(".form-check-label").count).to eq(2)
    end

    it "renders the container with the correct class" do
      rendered = render_inline(group)
      expect(rendered.css("div.mt-2")).not_to be_empty
    end

    it "passes the correct name to the rendered radio buttons" do
      expect(form_builder).to receive(:radio_button).with(:operator, "AND", any_args)

      # Use the same block pattern here for consistency and correctness.
      render_inline(group) do |g|
        g.add_radio_button(value: "AND", label: "And")
      end
    end
  end
end
