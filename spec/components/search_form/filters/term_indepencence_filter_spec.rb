require "rails_helper"

RSpec.describe(SearchForm::Filters::TermIndependenceFilter, type: :component) do
  let(:options) { {} }
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

  subject(:filter) do
    field_instance = described_class.new(**options)
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub I18n calls.
    allow(I18n).to receive(:t).with("admin.course.term_independent").and_return("Term Independent")

    # Set up mocks for rendering (needed for parent class).
    allow(form_state).to receive(:form).and_return(form_builder)
    allow(form_state).to receive(:with_form).and_return(form_state)
    allow(form_state).to receive(:label_for)
    allow(form_state).to receive(:element_id_for)
    allow(form_builder).to receive(:label)
    allow(form_builder).to receive(:check_box)
  end

  describe "#initialize" do
    it "initializes as a CheckboxField with correct, hard-coded options" do
      expect(filter.name).to eq(:term_independent)
      expect(filter.label).to eq("Term Independent")
      expect(filter.checked).to be(false)
    end

    context "with additional options" do
      let(:options) { { container_class: "custom-class" } }

      it "passes the additional options to the superclass" do
        expect(filter.container_class).to eq("custom-class")
      end
    end
  end
end
