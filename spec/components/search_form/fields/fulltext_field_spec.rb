require "rails_helper"

RSpec.describe(SearchForm::Fields::FulltextField, type: :component) do
  let(:form_state_double) { instance_double(SearchForm::Services::FormState) }
  let(:minimal_args) { { form_state: form_state_double } }

  subject(:field) { described_class.new(**minimal_args) }

  describe "#initialize" do
    it "assigns the form_state" do
      expect(field.form_state).to eq(form_state_double)
    end

    it "stores additional options" do
      instance = described_class.new(**minimal_args, placeholder: "Search...")
      expect(instance.options).to eq({ placeholder: "Search..." })
    end
  end

  describe "#setup_fields (via #before_render)" do
    let(:text_field_double) { instance_double(SearchForm::Fields::Primitives::TextField) }

    before do
      # The factory methods call `.with_form(form)`, which delegates `form` to `form_state`.
      allow(form_state_double).to receive(:form)

      # Spy on the factory method from the mixin to verify it's called correctly.
      allow(field).to receive(:create_text_field).and_return(text_field_double)
    end

    it "calls create_text_field with the correct, hard-coded arguments" do
      expected_args = {
        name: :fulltext,
        label: I18n.t("basics.fulltext"),
        help_text: I18n.t("search.helpdesks.fulltext_field")
      }

      expect(field).to receive(:create_text_field).with(hash_including(expected_args))

      # before_render is the public method that triggers the private setup_fields
      field.before_render
    end

    it "passes through additional options to the factory method" do
      field_with_options = described_class.new(**minimal_args, placeholder: "Search...")
      allow(field_with_options).to receive(:create_text_field).and_return(text_field_double)
      allow(field_with_options).to receive(:form_state).and_return(form_state_double)

      expect(field_with_options).to receive(:create_text_field)
        .with(hash_including(placeholder: "Search..."))

      field_with_options.before_render
    end
  end
end
