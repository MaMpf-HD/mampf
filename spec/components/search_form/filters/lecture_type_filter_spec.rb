# spec/components/search_form/filters/lecture_type_filter_spec.rb
require "rails_helper"

RSpec.describe(SearchForm::Filters::LectureTypeFilter, type: :component) do
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }
  let(:lecture_types) { [["Type A", "type_a"], ["Type B", "type_b"]] }

  subject(:filter) do
    field_instance = described_class.new
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub I18n calls from this class and its parent.
    allow(I18n).to receive(:t).with("basics.type").and_return("Type")
    allow(I18n).to receive(:t).with("admin.lecture.info.search_type").and_return("Help text")
    allow(I18n).to receive(:t).with("basics.all").and_return("All")
    allow(I18n).to receive(:t).with("basics.select").and_return("Please select")

    # Stub the external class method call that provides the collection.
    allow(Lecture).to receive(:select_sorts).and_return(lecture_types)

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
      expect(filter.name).to eq(:types)
      expect(filter.label).to eq("Type")
      expect(filter.help_text).to eq("Help text")
    end

    it "uses the collection from Lecture.select_sorts" do
      expect(filter.collection).to eq(lecture_types)
      expect(Lecture).to have_received(:select_sorts)
    end
  end
end
