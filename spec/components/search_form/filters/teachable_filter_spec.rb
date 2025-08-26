require "rails_helper"

RSpec.describe(SearchForm::Filters::TeachableFilter, type: :component) do
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }
  let(:course_relation) { double("Course::ActiveRecord_Relation") }

  # Create mock objects to simulate the database query result.
  let(:lecture_b) { instance_double(Lecture, short_title: "Lecture B", id: 2) }
  let(:lecture_a) { instance_double(Lecture, short_title: "Lecture A", id: 1) }
  let(:course) do
    instance_double(Course,
                    title: "My Course",
                    short_title: "MC",
                    id: 1,
                    lectures: [lecture_b, lecture_a])
  end
  let(:courses) { [course] }

  subject(:filter) do
    field_instance = described_class.new
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub I18n calls
    allow(I18n).to receive(:t).with("basics.associated_to").and_return("Associated to")
    allow(I18n).to receive(:t).with("admin.medium.info.search_teachable").and_return("Help text")
    allow(I18n).to receive(:t).with("basics.course").and_return("Course")
    allow(I18n).to receive(:t).with("basics.all").and_return("All") # From parent
    allow(I18n).to receive(:t).with("basics.select").and_return("Please select") # From parent

    # Stub the database query chain.
    allow(Course).to receive(:includes).with(lectures: :term).and_return(course_relation)
    allow(course_relation).to receive(:order).with(:title).and_return(courses)

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
    it "initializes with correct base options" do
      expect(filter.name).to eq(:teachable_ids)
      expect(filter.label).to eq("Associated to")
      expect(filter.help_text).to eq("Help text")
    end

    it "builds a grouped and sorted collection" do
      # The lectures should be sorted alphabetically by short_title.
      expected_collection = [
        ["My Course", [
          ["MC Course", "Course-1"],
          ["Lecture A", "Lecture-1"],
          ["Lecture B", "Lecture-2"]
        ]]
      ]
      expect(filter.collection).to eq(expected_collection)
    end

    it "initializes the radio group state to hidden" do
      expect(filter.show_radio_group?).to be(false)
    end
  end

  describe "configuration and hooks" do
    it "#with_inheritance_radios sets the show_radio_group flag to true" do
      filter.with_inheritance_radios
      expect(filter.show_radio_group?).to be(true)
    end

    it "#with_inheritance_radios returns self to allow for chaining" do
      expect(filter.with_inheritance_radios).to eq(filter)
    end
  end

  describe "#render_radio_group" do
    let(:radio_group_double) { instance_double(SearchForm::Controls::RadioGroup) }

    before do
      allow(SearchForm::Controls::RadioGroup).to receive(:new).and_return(radio_group_double)
      allow(filter).to receive(:render).with(radio_group_double).and_yield(radio_group_double)
                                       .and_return("Radio Group HTML")
      allow(radio_group_double).to receive(:add_radio_button)
    end

    context "when not configured" do
      it "returns nil" do
        expect(filter.render_radio_group).to be_nil
      end
    end

    context "when configured with #with_inheritance_radios" do
      before do
        filter.with_inheritance_radios
        allow(I18n).to receive(:t).with("basics.with_inheritance").and_return("With Inheritance")
        allow(I18n).to receive(:t).with("basics.without_inheritance")
                                  .and_return("Without Inheritance")
      end

      it "initializes a RadioGroup with the correct parameters" do
        expect(SearchForm::Controls::RadioGroup).to receive(:new)
          .with(form_state: form_state, name: :teachable_inheritance)
        filter.render_radio_group
      end

      it "adds the 'with' and 'without' inheritance radio buttons" do
        expect(radio_group_double).to receive(:add_radio_button)
          .with(hash_including(value: "1",
                               label: "With Inheritance", checked: true))
        expect(radio_group_double).to receive(:add_radio_button)
          .with(hash_including(value: "0",
                               label: "Without Inheritance", checked: false))
        filter.render_radio_group
      end
    end
  end

  describe "#all_toggle_data_attributes" do
    it "returns the correct hash of data attributes" do
      expected_data = {
        search_form_target: "allToggle",
        action: "change->search-form#toggleFromCheckbox change->search-form#toggleRadioGroup",
        toggle_radio_group: "teachable_inheritance",
        default_radio_value: "1"
      }
      expect(filter.all_toggle_data_attributes).to eq(expected_data)
    end
  end
end
