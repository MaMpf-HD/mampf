# spec/components/search_form/filters/term_filter_spec.rb
require "rails_helper"

RSpec.describe(SearchForm::Filters::TermFilter, type: :component) do
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }
  let(:terms) { [["WS 2025/26", 1], ["SS 2025", 2]] }

  subject(:filter) do
    field_instance = described_class.new
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub I18n calls from this class and its parent.
    allow(I18n).to receive(:t).with("basics.term").and_return("Term")
    allow(I18n).to receive(:t).with("admin.lecture.info.search_term").and_return("Help text")
    allow(I18n).to receive(:t).with("basics.all").and_return("All")
    allow(I18n).to receive(:t).with("basics.select").and_return("Please select")

    # Stub the external class method call that provides the collection.
    allow(Term).to receive(:select_terms).and_return(terms)

    # Set up mocks for rendering (needed for parent class).
    allow(form_state).to receive(:form).and_return(form_builder)
    allow(form_state).to receive(:with_form).and_return(form_state)
    allow(form_state).to receive(:label_for)
    allow(form_state).to receive(:element_id_for)
    allow(form_builder).to receive(:label)
    allow(form_builder).to receive(:select)
    allow(form_builder).to receive(:check_box)
  end

  describe "#initialize" do
    it "initializes as a MultiSelectField with correct, hard-coded options" do
      expect(filter.name).to eq(:term_ids)
      expect(filter.label).to eq("Term")
      expect(filter.help_text).to eq("Help text")
    end

    it "uses the collection from Term.select_terms" do
      # Accessing the filter's collection triggers the subject's initialization.
      expect(filter.collection).to eq(terms)
      # Now that the subject has been initialized, we can verify the method was called.
      expect(Term).to have_received(:select_terms)
    end
  end
end
