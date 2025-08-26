# spec/components/search_form/filters/program_filter_spec.rb
require "rails_helper"

RSpec.describe(SearchForm::Filters::ProgramFilter, type: :component) do
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }
  let(:program_relation) { double("Program::ActiveRecord_Relation") }

  # Create mock program objects to simulate the result of the query.
  let(:program_b) { instance_double(Program, name_with_subject: "Math: Algebra", id: 2) }
  let(:program_a) { instance_double(Program, name_with_subject: "Art: History", id: 1) }
  let(:programs) { [program_b, program_a] }

  subject(:filter) do
    field_instance = described_class.new
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub I18n calls from this class and its parent.
    allow(I18n).to receive(:t).with("basics.programs").and_return("Programs")
    allow(I18n).to receive(:t).with("admin.lecture.info.search_program").and_return("Help text")
    allow(I18n).to receive(:t).with("basics.all").and_return("All")
    allow(I18n).to receive(:t).with("basics.select").and_return("Please select")

    # Stub the database query chain.
    allow(Program).to receive(:includes).with(:subject, :translations,
                                              subject: :translations).and_return(program_relation)
    # The component calls .map on the relation, so we stub that.
    allow(program_relation).to receive(:map).and_return(programs.map { |p|
      [p.name_with_subject, p.id]
    })

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
      expect(filter.name).to eq(:program_ids)
      expect(filter.label).to eq("Programs")
      expect(filter.help_text).to eq("Help text")
    end

    it "builds the collection by formatting and sorting the program data" do
      # The `natural_sort_by` in the component should sort the collection.
      expected_collection = [
        ["Art: History", 1],
        ["Math: Algebra", 2]
      ]
      expect(filter.collection).to eq(expected_collection)
    end

    it "calls the correct query on the Program model" do
      # Trigger the subject to be initialized.
      filter
      expect(Program).to have_received(:includes).with(:subject, :translations,
                                                       subject: :translations)
    end
  end
end
