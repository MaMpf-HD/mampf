require "rails_helper"

RSpec.describe(SearchForm::Fields::TermIndependenceField, type: :component) do
  let(:form_state_double) { instance_double(SearchForm::Services::FormState) }
  let(:minimal_args) { { form_state: form_state_double } }

  subject(:field) { described_class.new(**minimal_args) }

  describe "#initialize" do
    it "assigns the form_state" do
      expect(field.instance_variable_get(:@form_state)).to eq(form_state_double)
    end

    it "stores additional options" do
      instance = described_class.new(**minimal_args, required: true)
      expect(instance.options).to eq({ required: true })
    end
  end

  describe "field creation" do
    let(:checkbox_field_double) { instance_double(SearchForm::Fields::Primitives::CheckboxField) }

    before do
      # The factory method calls .with_form(form), which delegates to form_state.
      allow(form_state_double).to receive(:form)
      # Stub the return of the factory to prevent further execution.
      allow(field).to receive(:create_checkbox_field).and_return(checkbox_field_double)
    end

    it "creates a checkbox field with the correct configuration" do
      expect(field).to receive(:create_checkbox_field) do |args|
        expect(args[:name]).to eq(:term_independent)
        expect(args[:label]).to eq(I18n.t("admin.course.term_independent"))
        expect(args[:help_text]).to eq(I18n.t("search.helpdesks.term_independence_field"))
        expect(args[:checked]).to be(false)
      end

      field.before_render
    end

    it "passes through additional options to the checkbox field" do
      field_with_options = described_class.new(**minimal_args, container_class: "custom-class")
      allow(field_with_options).to receive(:create_checkbox_field).and_return(checkbox_field_double)
      allow(field_with_options).to receive(:form_state).and_return(form_state_double)

      expect(field_with_options).to receive(:create_checkbox_field)
        .with(hash_including(container_class: "custom-class"))

      field_with_options.before_render
    end
  end
end
