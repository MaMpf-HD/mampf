# spec/components/search_form/controls/base_control_spec.rb
require "rails_helper"

RSpec.describe(SearchForm::Controls::BaseControl, type: :component) do
  # A concrete implementation of the abstract BaseControl for testing purposes.
  let!(:test_control_class) do
    Class.new(described_class) do
      def id_parts
        ["test", "control"]
      end
    end
  end

  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:stimulus_config) { { controller: "test" } }
  let(:options) { { class: "custom-class", "data-foo": "bar" } }

  subject(:control) do
    test_control_class.new(form_state: form_state, stimulus: stimulus_config, **options)
  end

  describe "#initialize" do
    it "assigns the form_state" do
      expect(control.form_state).to eq(form_state)
    end

    it "assigns the stimulus_config" do
      expect(control.stimulus_config).to eq(stimulus_config)
    end

    it "assigns the options" do
      expect(control.options).to eq(options)
    end
  end

  describe "delegation" do
    it "delegates #form to form_state" do
      expect(form_state).to receive(:form)
      control.form
    end

    it "delegates #context to form_state" do
      expect(form_state).to receive(:context)
      control.context
    end
  end

  describe "ID generation" do
    let(:expected_id_parts) { ["test", "control"] }

    it "#element_id calls form_state with the correct parts" do
      expect(form_state).to receive(:element_id_for).with(*expected_id_parts)
      control.element_id
    end

    it "#label_for calls form_state with the correct parts" do
      expect(form_state).to receive(:label_for).with(*expected_id_parts)
      control.label_for
    end
  end

  describe "#container_class" do
    context "when :container_class is not in options" do
      let(:options) { {} }

      it "returns the default class" do
        expect(control.container_class).to eq("form-check mb-2")
      end
    end

    context "when :container_class is provided in options" do
      let(:options) { { container_class: "my-custom-container" } }

      it "returns the provided class" do
        expect(control.container_class).to eq("my-custom-container")
      end
    end
  end

  describe "#data_attributes" do
    context "when :data is not in options" do
      let(:options) { {} }

      it "returns an empty hash" do
        expect(control.data_attributes).to eq({})
      end
    end

    context "when :data is provided in options" do
      let(:data_hash) { { controller: "hello" } }
      let(:options) { { data: data_hash } }

      it "returns the provided data hash" do
        expect(control.data_attributes).to eq(data_hash)
      end
    end
  end

  describe "#html_options" do
    let(:options) do
      {
        class: "my-class",
        container_class: "internal-only",
        data: { controller: "hello" }
      }
    end

    it "includes the data attributes hash" do
      expect(control.html_options[:data]).to eq({ controller: "hello" })
    end

    it "includes other standard HTML options" do
      expect(control.html_options[:class]).to eq("my-class")
    end

    it "filters out internal options like :container_class" do
      expect(control.html_options).not_to have_key(:container_class)
    end

    context "when data attributes are empty" do
      let(:options) { { class: "my-class" } }

      it "does not include the data key" do
        expect(control.html_options).not_to have_key(:data)
      end
    end
  end

  describe "#with_form" do
    let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

    it "calls with_form on the form_state object" do
      expect(form_state).to receive(:with_form).with(form_builder)
      control.with_form(form_builder)
    end

    it "returns self for chaining" do
      allow(form_state).to receive(:with_form)
      expect(control.with_form(form_builder)).to be(control)
    end
  end

  describe "abstract methods" do
    it "#id_parts raises a NotImplementedError on the base class" do
      base_instance = described_class.new(form_state: form_state)
      expect { base_instance.send(:id_parts) }.to raise_error(NotImplementedError)
    end
  end
end
