require "rails_helper"

RSpec.describe(SearchForm::Filters::FulltextFilter, type: :component) do
  let(:options) { {} }
  let(:form_state) { instance_double(SearchForm::Services::FormState) }

  subject(:filter) do
    field_instance = described_class.new(**options)
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub I18n calls to make tests independent of translation files.
    allow(I18n).to receive(:t).with("basics.fulltext").and_return("Full-text Search")
    allow(I18n).to receive(:t).with("admin.lecture.info.search_fulltext")
                              .and_return("Search in content.")
  end

  describe "#initialize" do
    it "initializes as a TextField with correct, hard-coded options" do
      expect(filter.name).to eq(:fulltext)
      expect(filter.label).to eq("Full-text Search")
      expect(filter.help_text).to eq("Search in content.")
    end

    context "with additional options" do
      let(:options) { { placeholder: "Enter search term...", container_class: "custom-class" } }

      it "passes the additional options to the superclass" do
        # These options are handled by the base Field class.
        expect(filter.options[:placeholder]).to eq("Enter search term...")
        expect(filter.container_class).to eq("custom-class")
      end
    end
  end
end
