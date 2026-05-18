require "rails_helper"

RSpec.describe(SearchForm::Fields::MediumAccessField, type: :component) do
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
    let(:select_field_double) { instance_double(SearchForm::Fields::Primitives::SelectField) }

    before do
      # The factory method calls .with_form(form), which delegates to form_state.
      allow(form_state_double).to receive(:form)
      # Stub the return of the factory to prevent further execution.
      allow(field).to receive(:create_select_field).and_return(select_field_double)
    end

    it "creates a select field with the correct configuration" do
      expect(field).to receive(:create_select_field) do |args|
        expect(args[:name]).to eq(:access)
        expect(args[:label]).to eq(I18n.t("basics.access_rights"))
        expect(args[:collection]).to be_an(Array)
        expect(args[:collection].first).to eq([I18n.t("access.irrelevant"), "irrelevant"])
        expect(args[:selected]).to eq("irrelevant")
      end

      field.before_render
    end

    it "passes through additional options to the select field" do
      field_with_options = described_class.new(**minimal_args, required: true)
      allow(field_with_options).to receive(:create_select_field).and_return(select_field_double)
      allow(field_with_options).to receive(:form_state).and_return(form_state_double)

      expect(field_with_options).to receive(:create_select_field)
        .with(hash_including(required: true))

      field_with_options.before_render
    end
  end
end
