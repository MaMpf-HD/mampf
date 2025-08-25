require "rails_helper"

RSpec.describe(SearchForm::Controls::RadioButton, type: :component) do
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:name) { :operator }
  let(:value) { "AND" }
  let(:label) { "And" }
  let(:checked) { false }
  let(:stimulus_config) { {} }
  let(:options) { {} }

  subject(:control) do
    described_class.new(
      form_state: form_state,
      name: name,
      value: value,
      label: label,
      checked: checked,
      stimulus: stimulus_config,
      **options
    )
  end

  describe "#initialize" do
    it "assigns the name, value, label, and checked state" do
      expect(control.name).to eq(name)
      expect(control.value).to eq(value)
      expect(control.label).to eq(label)
      expect(control.checked).to be(checked)
    end
  end

  describe "ID generation" do
    it "uses both name and value for the ID parts" do
      expect(form_state).to receive(:element_id_for).with(name, value)
      control.element_id
    end
  end

  describe "#default_container_class" do
    context "when inline option is false" do
      let(:options) { { inline: false } }
      it "returns the default class" do
        expect(control.default_container_class).to eq("form-check mb-2")
      end
    end

    context "when inline option is true" do
      let(:options) { { inline: true } }
      it "returns the inline class" do
        expect(control.default_container_class).to eq("form-check form-check-inline")
      end
    end
  end

  describe "#data_attributes" do
    context "with :radio_toggle stimulus config" do
      let(:stimulus_config) { { radio_toggle: true } }

      it "adds radio toggle target and action" do
        expect(control.data_attributes).to include(
          search_form_target: "radioToggle",
          action: "change->search-form#toggleFromRadio"
        )
      end
    end

    context "with :controls_select stimulus config" do
      let(:stimulus_config) { { controls_select: "some-target" } }

      it "adds controls_select attribute" do
        expect(control.data_attributes).to include(controls_select: "some-target")
      end
    end
  end

  describe "#radio_button_html_options" do
    before do
      allow(form_state).to receive(:element_id_for).and_return("generated_id")
    end

    it "includes a default class, checked state, and generated id" do
      expect(control.radio_button_html_options).to include(
        class: "form-check-input",
        checked: checked,
        id: "generated_id"
      )
    end

    it "includes the disabled attribute if present in options" do
      options[:disabled] = true
      expect(control.radio_button_html_options[:disabled]).to be(true)
    end

    it "does not include the disabled attribute if not present" do
      expect(control.radio_button_html_options).not_to have_key(:disabled)
    end

    it "filters out internal options like :inline and :container_class" do
      options[:inline] = true
      options[:container_class] = "custom"
      expect(control.radio_button_html_options).not_to have_key(:inline)
      expect(control.radio_button_html_options).not_to have_key(:container_class)
    end
  end

  describe "rendering" do
    let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

    before do
      allow(form_state).to receive(:with_form).and_return(form_state)
      allow(form_state).to receive(:form).and_return(form_builder)
      allow(form_state).to receive(:label_for).with(name, value).and_return("op_and_label")
      allow(form_state).to receive(:element_id_for).with(name, value).and_return("op_and_id")

      allow(form_builder).to receive(:radio_button)
      allow(form_builder).to receive(:label)
    end

    it "renders without errors" do
      expect { render_inline(control) }.not_to raise_error
    end

    it "calls the form builder's radio_button helper with the correct arguments" do
      expect(form_builder).to receive(:radio_button).with(name, value,
                                                          control.radio_button_html_options)
      render_inline(control)
    end

    it "calls the form builder's label helper with the correct arguments" do
      expect(form_builder).to receive(:label).with("op_and_label", "And", class: "form-check-label")
      render_inline(control)
    end

    it "renders a div with the correct container class" do
      rendered = render_inline(control)
      expect(rendered.css("div.form-check.mb-2")).not_to be_empty
    end
  end
end
