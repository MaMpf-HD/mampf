require "rails_helper"

RSpec.describe(SearchForm::Fields::AnswerCountField, type: :component) do
  let(:form_state_double) { instance_double(SearchForm::Services::FormState) }
  let(:minimal_args) { { form_state: form_state_double } }

  subject(:field) { described_class.new(**minimal_args) }

  describe "#initialize" do
    it "assigns the form_state and default purpose" do
      expect(field.form_state).to eq(form_state_double)
      expect(field.purpose).to eq("media")
    end

    it "stores a custom purpose and additional options" do
      instance = described_class.new(**minimal_args, purpose: "custom", disabled: true)
      expect(instance.purpose).to eq("custom")
      expect(instance.options).to eq({ disabled: true })
    end
  end

  describe "#render?" do
    it "returns false if purpose is 'import', true otherwise" do
      expect(described_class.new(**minimal_args, purpose: "media").render?).to be(true)
      expect(described_class.new(**minimal_args, purpose: "import").render?).to be(false)
    end
  end

  describe "field creation" do
    it "creates a select field with the correct configuration" do
      expect(field).to receive(:create_select_field) do |args|
        expect(args[:name]).to eq(:answers_count)
        expect(args[:label]).to eq(I18n.t("basics.answer_count"))
        expect(args[:collection]).to be_an(Array)
        expect(args[:collection].first).to eq([I18n.t("access.irrelevant"), "irrelevant"])
        expect(args[:selected]).to eq("irrelevant")
      end

      field.before_render
    end

    it "passes through additional options to the select field" do
      field_with_options = described_class.new(**minimal_args, required: true)

      expect(field_with_options).to receive(:create_select_field)
        .with(hash_including(required: true))

      field_with_options.before_render
    end
  end
end
