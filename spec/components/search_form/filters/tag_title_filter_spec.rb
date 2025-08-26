require "rails_helper"

RSpec.describe(SearchForm::Filters::TagTitleFilter, type: :component) do
  let(:options) { {} }
  let(:form_state) { instance_double(SearchForm::Services::FormState) }

  subject(:filter) do
    field_instance = described_class.new(**options)
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub I18n calls to make tests independent of translation files.
    allow(I18n).to receive(:t).with("basics.title").and_return("Title")
    allow(I18n).to receive(:t).with("admin.tag.info.search_title").and_return("Search by title.")
  end

  describe "#initialize" do
    it "initializes as a TextField with correct, hard-coded options" do
      expect(filter.name).to eq(:title)
      expect(filter.label).to eq("Title")
      expect(filter.help_text).to eq("Search by title.")
    end

    context "with additional options" do
      let(:options) { { placeholder: "Enter tag title...", container_class: "custom-class" } }

      it "passes the additional options to the superclass" do
        # The :placeholder option is stored in the generic options hash.
        expect(filter.options[:placeholder]).to eq("Enter tag title...")
        # The :container_class is a named argument and has its own reader.
        expect(filter.container_class).to eq("custom-class")
      end
    end
  end
end
