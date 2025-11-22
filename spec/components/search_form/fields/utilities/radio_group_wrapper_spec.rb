require "rails_helper"

RSpec.describe(SearchForm::Fields::Utilities::RadioGroupWrapper, type: :component) do
  let(:view_context) { instance_double("ViewContext", safe_join: nil, content_tag: nil) }
  let(:radio1) { double("RadioButton1") }
  let(:radio2) { double("RadioButton2") }

  subject(:wrapper) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(wrapper.name).to be_nil
      expect(wrapper.parent_field).to be_nil
      expect(wrapper.radio_buttons).to eq([])
      expect(wrapper.legend).to be_nil
      expect(wrapper.instance_variable_get(:@legend_class)).to eq("visually-hidden")
      expect(wrapper.options).to eq({})
    end

    it "assigns all provided values" do
      parent_field = double("ParentField")
      options = { class: "custom-class" }
      instance = described_class.new(
        name: :group_name,
        parent_field: parent_field,
        radio_buttons: [radio1],
        legend: "Custom Legend",
        legend_class: "custom-legend",
        **options
      )

      expect(instance.name).to eq(:group_name)
      expect(instance.parent_field).to eq(parent_field)
      expect(instance.radio_buttons).to eq([radio1])
      expect(instance.legend).to eq("Custom Legend")
      expect(instance.instance_variable_get(:@legend_class)).to eq("custom-legend")
      expect(instance.options).to eq(options)
    end
  end

  describe "#with_radio_buttons" do
    it "sets and flattens the radio buttons" do
      wrapper.with_radio_buttons([radio1], radio2)
      expect(wrapper.radio_buttons).to eq([radio1, radio2])
    end

    it "returns self for method chaining" do
      expect(wrapper.with_radio_buttons(radio1)).to be(wrapper)
    end
  end

  describe "#render" do
    let(:rendered_collection) { "<div>Radios</div>".html_safe }

    before do
      # Stub the shared method since its internals are tested elsewhere.
      allow(wrapper).to receive(:auto_render_collection).and_return(rendered_collection)
      # Stub the final join call.
      allow(view_context).to receive(:safe_join)
    end

    it "renders a fieldset with a radiogroup role" do
      expect(view_context).to receive(:content_tag)
        .with(:fieldset, hash_including(role: "radiogroup"))
        .and_yield
      wrapper.render(view_context)
    end

    it "includes custom classes on the fieldset" do
      wrapper.options[:class] = "custom-fieldset"
      expect(view_context).to receive(:content_tag)
        .with(:fieldset, hash_including(class: "custom-fieldset"))
        .and_yield
      wrapper.render(view_context)
    end

    it "includes aria-labelledby if resolved" do
      allow(wrapper).to receive(:resolved_aria_labelledby).and_return("parent_label_id")
      expect(view_context).to receive(:content_tag)
        .with(:fieldset, hash_including("aria-labelledby": "parent_label_id"))
        .and_yield
      wrapper.render(view_context)
    end

    it "renders a legend tag with the resolved legend text" do
      allow(wrapper).to receive(:resolved_legend).and_return("My Legend")
      allow(view_context).to receive(:content_tag).with(:fieldset, anything).and_yield
      expect(view_context).to receive(:content_tag)
        .with(:legend, "My Legend", class: "visually-hidden")

      wrapper.render(view_context)
    end

    it "calls auto_render_collection with the correct arguments" do
      wrapper.with_radio_buttons(radio1)
      allow(view_context).to receive(:content_tag).with(:fieldset, anything).and_yield
      expect(wrapper).to receive(:auto_render_collection)
        .with(view_context, [radio1], wrapper_class: "mt-2")

      wrapper.render(view_context)
    end

    it "joins the legend and the rendered collection" do
      legend_html = "<legend>My Legend</legend>".html_safe
      allow(wrapper).to receive(:resolved_legend).and_return("My Legend")
      allow(view_context).to receive(:content_tag).with(:legend, "My Legend",
                                                        class: "visually-hidden")
                                                  .and_return(legend_html)
      allow(view_context).to receive(:content_tag).with(:fieldset, anything).and_yield
      expect(view_context).to receive(:safe_join).with([legend_html, rendered_collection])
      wrapper.render(view_context)
    end
  end

  describe "#resolved_legend" do
    it "prioritizes an explicit legend" do
      instance = described_class.new(legend: "Explicit Legend", name: :group_name)
      expect(instance.send(:resolved_legend)).to eq("Explicit Legend")
    end

    it "falls back to the parent field's label" do
      parent_field = double("ParentField", label: "Parent Label")
      instance = described_class.new(parent_field: parent_field, name: :group_name)
      expect(instance.send(:resolved_legend)).to eq("Parent Label options")
    end

    it "falls back to the group name" do
      instance = described_class.new(name: :group_name)
      expect(instance.send(:resolved_legend)).to eq("Group name options")
    end

    it "uses a generic default as a last resort" do
      expect(wrapper.send(:resolved_legend)).to eq("Radio group options")
    end
  end
end
