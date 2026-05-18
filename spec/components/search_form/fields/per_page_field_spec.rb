require "rails_helper"

RSpec.describe(SearchForm::Fields::PerPageField, type: :component) do
  let(:form_state_double) { instance_double(SearchForm::Services::FormState) }
  let(:minimal_args) { { form_state: form_state_double } }

  subject(:field) { described_class.new(**minimal_args) }

  describe "#initialize" do
    it "assigns form_state and default values" do
      expect(field.instance_variable_get(:@form_state)).to eq(form_state_double)
      expect(field.per_options).to eq([[10, 10], [20, 20], [50, 50]])
      expect(field.default).to eq(10)
    end

    it "stores custom arguments and additional options" do
      custom_options = [[5, 5], [15, 15]]
      instance = described_class.new(
        **minimal_args,
        per_options: custom_options,
        default: 15,
        required: true
      )
      expect(instance.per_options).to eq(custom_options)
      expect(instance.default).to eq(15)
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

    it "creates a select field with the correct default configuration" do
      expect(field).to receive(:create_select_field) do |args|
        expect(args[:name]).to eq(:per)
        expect(args[:label]).to eq(I18n.t("basics.hits_per_page"))
        # Check the properties of the collection, not the exact implementation.
        expect(args[:collection]).to be_an(Array)
        expect(args[:collection].first).to eq([10, 10])
        expect(args[:selected]).to eq(10)
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
