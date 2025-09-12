require "rails_helper"

RSpec.describe(SearchForm::Fields::Utilities::GroupWrapperShared, type: :component) do
  # Create a dummy class that includes the mixin for isolated testing.
  let(:dummy_wrapper_class) do
    Class.new do
      include SearchForm::Fields::Utilities::GroupWrapperShared
      attr_accessor :parent_field, :options

      def initialize(parent_field: nil, **options)
        @parent_field = parent_field
        @options = options
      end

      # The `wrap` method calls `render`, so we need a dummy implementation.
      def render(_view_context, &)
        "render called"
      end
    end
  end

  let(:view_context) { instance_double("ViewContext") }
  subject(:wrapper) { dummy_wrapper_class.new }

  describe "#wrap" do
    it "calls the render method" do
      expect(wrapper).to receive(:render).with(view_context)
      wrapper.wrap(view_context)
    end
  end

  describe "#resolved_aria_labelledby" do
    context "when aria_labelledby is provided in options" do
      it "returns the value from options" do
        wrapper.options = { aria_labelledby: "explicit_id" }
        expect(wrapper.send(:resolved_aria_labelledby)).to eq("explicit_id")
      end
    end

    context "when a parent_field is present" do
      it "delegates to the parent field's form_state" do
        form_state_double = instance_double(SearchForm::Services::FormState)
        parent_field_double = instance_double(SearchForm::Fields::Primitives::SelectField,
                                              name: :parent_name, form_state: form_state_double)
        wrapper.parent_field = parent_field_double

        expect(form_state_double).to receive(:element_id_for).with(:parent_name)
                                                             .and_return("generated_id")
        expect(wrapper.send(:resolved_aria_labelledby)).to eq("generated_id")
      end
    end

    context "when no source is available" do
      it "returns nil" do
        wrapper.options = {}
        wrapper.parent_field = nil
        expect(wrapper.send(:resolved_aria_labelledby)).to be_nil
      end
    end
  end

  describe "#auto_render_collection" do
    let(:collection) { [double("Item1"), double("Item2")] }

    context "when a block is provided" do
      it "captures and returns the block's content" do
        captured_content = "<div>Block Content</div>"
        allow(view_context).to receive(:capture).and_return(captured_content)
        # The implementation uses safe_join, so we need to allow it.
        # We'll have it pass through the value it receives.
        allow(view_context).to receive(:safe_join).and_return(captured_content)

        result = wrapper.send(:auto_render_collection, view_context, []) do
          # This block's execution is handled by the mock
        end

        expect(result).to eq(captured_content)
      end
    end
    context "when a collection is provided without a block" do
      let(:collection) { [double("Item1"), double("Item2")] }
      let(:rendered_items) { ["<span>Item 1</span>", "<span>Item 2</span>"] }
      let(:joined_items) { rendered_items.join.html_safe }

      before do
        # Stub the individual render calls
        allow(view_context).to receive(:render).with(collection[0]).and_return(rendered_items[0])
        allow(view_context).to receive(:render).with(collection[1]).and_return(rendered_items[1])

        # Stub the safe_join calls
        allow(view_context).to receive(:safe_join).with(rendered_items).and_return(joined_items)
        allow(view_context).to receive(:safe_join).with([joined_items]).and_return(joined_items)
        allow(view_context).to receive(:safe_join).with([]).and_return("".html_safe)
      end

      it "renders each item in the collection" do
        expect(view_context).to receive(:render).with(collection[0])
        expect(view_context).to receive(:render).with(collection[1])
        wrapper.send(:auto_render_collection, view_context, collection)
      end

      it "joins the rendered items without a wrapper div by default" do
        result = wrapper.send(:auto_render_collection, view_context, collection)
        expect(result).to eq(joined_items)
      end

      it "wraps the rendered items in a div if wrapper_class is provided" do
        # rubocop:disable Rails/OutputSafety
        wrapped_content = "<div class=\"wrapper\">#{joined_items}</div>".html_safe
        # rubocop:enable Rails/OutputSafety
        allow(view_context).to receive(:content_tag)
          .with(:div, class: "wrapper")
          .and_return(wrapped_content)
        allow(view_context).to receive(:safe_join).with([wrapped_content])
                                                  .and_return(wrapped_content)

        result = wrapper.send(:auto_render_collection, view_context, collection,
                              wrapper_class: "wrapper")
        expect(result).to eq(wrapped_content)
      end
    end

    context "when both block and collection are empty" do
      it "returns an empty safe string" do
        # The implementation calls safe_join on an empty array in this case.
        allow(view_context).to receive(:safe_join).with([]).and_return("".html_safe)

        result = wrapper.send(:auto_render_collection, view_context, [])
        expect(result).to eq("")
        expect(result).to be_html_safe
      end
    end
  end
end
