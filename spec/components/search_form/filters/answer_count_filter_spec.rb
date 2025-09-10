require "rails_helper"

RSpec.describe(SearchForm::Filters::AnswerCountFilter, type: :component) do
  let(:purpose) { "media" }
  let(:options) { { purpose: purpose } }
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

  subject(:filter) do
    field_instance = described_class.new(**options)
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub I18n calls to make tests independent of translation files
    allow(I18n).to receive(:t).with("basics.answer_count").and_return("Answer Count")
    allow(I18n).to receive(:t).with("admin.medium.info.answer_count").and_return("Help text")
    allow(I18n).to receive(:t).with("access.irrelevant").and_return("Irrelevant")
  end

  describe "#initialize" do
    it "stores the purpose" do
      expect(filter.send(:purpose)).to eq("media")
    end

    it "initializes as a SelectField with correct, hard-coded options" do
      expect(filter.name).to eq(:answers_count)
      expect(filter.label).to eq("Answer Count")
      expect(filter.help_text).to eq("Help text")
      expect(filter.selected).to eq("irrelevant")
      expect(filter.collection.size).to eq(8)
      expect(filter.collection.first).to eq(["Irrelevant", "irrelevant"])
    end

    context "with 'import' purpose" do
      let(:purpose) { "import" }

      it "stores the purpose" do
        expect(filter.send(:purpose)).to eq("import")
      end

      it "still fully initializes the component" do
        # This is important to ensure the object is valid even if it won't render.
        expect(filter.name).to eq(:answers_count)
        expect(filter.label).to eq("Answer Count")
        expect(filter).to be_a(SearchForm::Fields::Primitives::SelectField)
      end
    end
  end

  describe "#call" do
    before do
      # Set up mocks for rendering, needed for the non-import case.
      allow(form_state).to receive(:form).and_return(form_builder)
      allow(form_state).to receive(:with_form).and_return(form_state)
      allow(form_state).to receive(:label_for).with(:answers_count).and_return("some_label_id")
      allow(form_state).to receive(:element_id_for).with(:answers_count)
                                                   .and_return("some_element_id")
      allow(form_builder).to receive(:label)
      allow(form_builder).to receive(:select)
    end

    context "when purpose is 'media'" do
      let(:purpose) { "media" }

      it "renders the component" do
        # We expect content because super is called.
        expect(render_inline(filter).to_s).not_to be_empty
      end
    end

    context "when purpose is 'import'" do
      let(:purpose) { "import" }

      it "does not render the component" do
        # We expect no content because render? returns false.
        expect(render_inline(filter).to_s).to be_empty
      end
    end
  end
end
