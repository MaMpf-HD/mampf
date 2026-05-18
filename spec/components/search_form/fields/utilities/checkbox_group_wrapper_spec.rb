require "rails_helper"

RSpec.describe(SearchForm::Fields::Utilities::CheckboxGroupWrapper, type: :component) do
  let(:view_context) { instance_double("ViewContext") }
  let(:checkbox1) { double("Checkbox1") }
  let(:checkbox2) { double("Checkbox2") }

  subject(:wrapper) { described_class.new }

  describe "#initialize" do
    it "sets default values" do
      expect(wrapper.checkboxes).to eq([])
      expect(wrapper.instance_variable_get(:@wrap_in_group)).to be(true)
    end

    it "flattens the checkboxes array" do
      instance = described_class.new(checkboxes: [[checkbox1], checkbox2])
      expect(instance.checkboxes).to eq([checkbox1, checkbox2])
    end
  end

  describe "#with_checkboxes" do
    it "sets and flattens the checkboxes" do
      wrapper.with_checkboxes([checkbox1], checkbox2)
      expect(wrapper.checkboxes).to eq([checkbox1, checkbox2])
    end

    it "returns self for method chaining" do
      expect(wrapper.with_checkboxes(checkbox1)).to be(wrapper)
    end
  end

  describe "#render" do
    let(:rendered_content) { "<span>Rendered Checkboxes</span>".html_safe }

    before do
      # We test auto_render_collection's internals elsewhere. Here, we just
      # stub it to confirm it's called and to provide its output.
      allow(wrapper).to receive(:auto_render_collection).and_return(rendered_content)
    end

    context "when wrap_in_group is true (default)" do
      it "calls auto_render_collection with its checkboxes" do
        wrapper.with_checkboxes(checkbox1)
        expect(wrapper).to receive(:auto_render_collection).with(view_context, [checkbox1])
        allow(view_context).to receive(:content_tag) # Prevent further execution
        wrapper.render(view_context)
      end

      it "wraps the content in a div with correct group options" do
        # Stub the shared method that resolves the label
        allow(wrapper).to receive(:resolved_aria_labelledby).and_return("parent_label_id")
        wrapper.options[:class] = "custom-group"

        expected_group_options = {
          role: "group",
          "aria-labelledby": "parent_label_id",
          class: "custom-group"
        }

        # Expect `content_tag` to be called with the options hash and a block.
        # We use `.and_yield` to simulate the execution of that block.
        expect(view_context).to receive(:content_tag)
          .with(:div, expected_group_options)
          .and_yield

        wrapper.render(view_context)
      end
    end

    context "when wrap_in_group is false" do
      subject(:wrapper) { described_class.new(wrap_in_group: false) }

      it "returns the rendered content directly without a wrapping div" do
        expect(view_context).not_to receive(:content_tag)
        expect(wrapper.render(view_context)).to eq(rendered_content)
      end
    end
  end
end
