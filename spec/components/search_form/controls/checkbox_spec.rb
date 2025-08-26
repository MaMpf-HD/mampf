require "rails_helper"

RSpec.describe(SearchForm::Controls::Checkbox, type: :component) do
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:name) { :all_media }
  let(:label) { "All Media" }
  let(:checked) { false }
  let(:stimulus_config) { {} }
  let(:options) { {} }

  subject(:control) do
    described_class.new(
      form_state: form_state,
      name: name,
      label: label,
      checked: checked,
      stimulus: stimulus_config,
      **options
    )
  end

  describe "#initialize" do
    it "assigns the name" do
      expect(control.name).to eq(name)
    end

    it "assigns the label" do
      expect(control.label).to eq(label)
    end

    it "assigns the checked state" do
      expect(control.checked).to be(false)
    end

    it "correctly passes options to the superclass" do
      # This implicitly tests that `super` was called correctly
      expect(control.form_state).to eq(form_state)
    end
  end

  describe "ID generation" do
    it "uses its name for the ID parts" do
      # We test the private `id_parts` method via its public consumers
      expect(form_state).to receive(:element_id_for).with(name)
      control.element_id
    end
  end

  describe "#data_attributes" do
    context "with no stimulus config" do
      it "returns the base data attributes from options" do
        options[:data] = { "foo" => "bar" }
        expect(control.data_attributes).to eq({ "foo" => "bar" })
      end
    end

    context "with :toggle stimulus config" do
      let(:stimulus_config) { { toggle: true } }

      it "adds toggle target and action" do
        expect(control.data_attributes).to include(
          search_form_target: "allToggle",
          action: "change->search-form#toggleFromCheckbox"
        )
      end
    end

    context "with :toggle_radio_group stimulus config" do
      let(:stimulus_config) do
        {
          toggle_radio_group: "operator-radios",
          default_radio_value: "AND"
        }
      end

      it "adds radio toggle action" do
        expect(control.data_attributes[:action]).to eq("change->search-form#toggleRadioGroup")
      end

      it "adds toggle_radio_group attribute" do
        expect(control.data_attributes[:toggle_radio_group]).to eq("operator-radios")
      end

      it "adds default_radio_value attribute" do
        expect(control.data_attributes[:default_radio_value]).to eq("AND")
      end
    end

    context "with both toggle and toggle_radio_group stimulus config" do
      let(:stimulus_config) do
        {
          toggle: true,
          toggle_radio_group: "operator-radios"
        }
      end

      it "combines both actions in the action string" do
        expected_actions = [
          "change->search-form#toggleFromCheckbox",
          "change->search-form#toggleRadioGroup"
        ]
        expect(control.data_attributes[:action]).to eq(expected_actions.join(" "))
      end
    end
  end

  describe "#checkbox_html_options" do
    before do
      allow(form_state).to receive(:element_id_for).and_return("generated_id")
    end

    it "includes a default class" do
      expect(control.checkbox_html_options[:class]).to eq("form-check-input")
    end

    it "includes the checked state" do
      expect(control.checkbox_html_options[:checked]).to be(checked)
    end

    it "includes the generated element id" do
      expect(control.checkbox_html_options[:id]).to eq("generated_id")
    end

    it "merges other html options" do
      options[:"aria-label"] = "Custom Label"
      expect(control.checkbox_html_options[:"aria-label"]).to eq("Custom Label")
    end

    it "includes data attributes if they exist" do
      allow(control).to receive(:data_attributes).and_return({ action: "test" })
      expect(control.checkbox_html_options[:data]).to eq({ action: "test" })
    end

    it "does not include data key if data attributes are empty" do
      allow(control).to receive(:data_attributes).and_return({})
      expect(control.checkbox_html_options).not_to have_key(:data)
    end
  end

  describe "rendering" do
    let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

    before do
      # Mock the form_state methods that will be called during render
      allow(form_state).to receive(:with_form).and_return(form_state)
      allow(form_state).to receive(:form).and_return(form_builder)
      allow(form_state).to receive(:label_for).with(:all_media).and_return("all_media_label")
      allow(form_state).to receive(:element_id_for).with(:all_media).and_return("all_media_id")
      # Mock the form_builder methods
      allow(form_builder).to receive(:check_box)
      allow(form_builder).to receive(:label)
    end

    it "renders without errors" do
      expect { render_inline(control) }.not_to raise_error
    end

    it "calls the form builder's check_box helper with the correct arguments" do
      expect(form_builder).to receive(:check_box).with(:all_media, control.checkbox_html_options)
      render_inline(control)
    end

    it "calls the form builder's label helper with the correct arguments" do
      expect(form_builder).to receive(:label).with("all_media_label", "All Media",
                                                   class: "form-check-label")
      render_inline(control)
    end

    it "renders a div with the correct container class" do
      rendered = render_inline(control)
      expect(rendered.css("div.form-check.mb-2")).not_to be_empty
    end
  end
end
