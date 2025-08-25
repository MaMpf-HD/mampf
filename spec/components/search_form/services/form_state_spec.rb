# spec/components/search_form/services/form_state_spec.rb
require "rails_helper"

RSpec.describe(SearchForm::Services::FormState, type: :component) do
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder, object_name: "custom_scope") }

  describe "#initialize" do
    context "with default parameters" do
      subject(:state) { described_class.new }

      it "initializes with nil form and context" do
        expect(state.form).to be_nil
        expect(state.context).to be_nil
      end

      it "sets a default scope_prefix" do
        expect(state.scope_prefix).to eq("search")
      end
    end

    context "with a context provided" do
      subject(:state) { described_class.new(context: "media") }

      it "stores the context" do
        expect(state.context).to eq("media")
      end
    end

    context "with a form builder provided at initialization" do
      subject(:state) { described_class.new(form: form_builder) }

      it "stores the form builder" do
        expect(state.form).to eq(form_builder)
      end

      it "sets the scope_prefix from the form builder's object_name" do
        expect(state.scope_prefix).to eq("custom_scope")
      end
    end
  end

  describe "#with_form" do
    subject(:state) { described_class.new(context: "media") }

    it "assigns the form builder to the state" do
      expect { state.with_form(form_builder) }.to change { state.form }.from(nil).to(form_builder)
    end

    it "updates the scope_prefix based on the new form builder" do
      expect { state.with_form(form_builder) }.to change {
        state.scope_prefix
      }.from("search").to("custom_scope")
    end

    it "returns itself to allow for method chaining" do
      expect(state.with_form(form_builder)).to be(state)
    end
  end

  describe "ID generation" do
    context "when no context is provided" do
      subject(:state) { described_class.new }

      it "#base_id_for generates an ID from parts only" do
        expect(state.base_id_for("field", "name")).to eq("field_name")
      end

      it "#element_id_for prepends the default scope" do
        expect(state.element_id_for("field", "name")).to eq("search_field_name")
      end

      it "#label_for returns the base ID" do
        expect(state.label_for("field", "name")).to eq("field_name")
      end
    end

    context "when a context is provided" do
      subject(:state) { described_class.new(context: "media") }

      it "#base_id_for prepends the context" do
        expect(state.base_id_for("field", "name")).to eq("media_field_name")
      end

      it "#element_id_for prepends scope and context" do
        expect(state.element_id_for("field", "name")).to eq("search_media_field_name")
      end

      it "#label_for returns the context-aware base ID" do
        expect(state.label_for("field", "name")).to eq("media_field_name")
      end
    end

    context "when context and a custom scope are present" do
      subject(:state) { described_class.new(context: "media", form: form_builder) }

      it "#base_id_for prepends the context" do
        expect(state.base_id_for("field")).to eq("media_field")
      end

      it "#element_id_for prepends the custom scope and context" do
        expect(state.element_id_for("field")).to eq("custom_scope_media_field")
      end

      it "#label_for returns the context-aware base ID" do
        expect(state.label_for("field")).to eq("media_field")
      end
    end

    context "with various parts" do
      subject(:state) { described_class.new(context: "ctx") }

      it "handles symbols correctly" do
        expect(state.base_id_for(:field, :name)).to eq("ctx_field_name")
      end

      it "rejects empty or nil parts" do
        expect(state.base_id_for("field", nil, "name", "")).to eq("ctx_field_name")
      end

      it "handles a single part" do
        expect(state.base_id_for("field")).to eq("ctx_field")
      end
    end
  end
end
