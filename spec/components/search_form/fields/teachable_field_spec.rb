require "rails_helper"

RSpec.describe(SearchForm::Fields::TeachableField, type: :component) do
  let(:form_state_double) { instance_double(SearchForm::Services::FormState) }
  let(:minimal_args) { { form_state: form_state_double } }

  subject(:field) { described_class.new(**minimal_args) }

  describe "#initialize" do
    it "assigns the form_state" do
      expect(field.instance_variable_get(:@form_state)).to eq(form_state_double)
    end

    it "stores additional options" do
      instance = described_class.new(**minimal_args, required: true)
      expect(instance.options).to eq({ required: true })
    end
  end

  describe "#setup_fields (via #before_render)" do
    let(:multi_select_double) { instance_double(SearchForm::Fields::Primitives::MultiSelectField, "multi_select") }
    let(:all_checkbox_double) { instance_double(SearchForm::Fields::Primitives::CheckboxField, "all_checkbox") }
    let(:with_inheritance_radio_double) { instance_double(SearchForm::Fields::Primitives::RadioButtonField, "with_inheritance_radio") }
    let(:without_inheritance_radio_double) { instance_double(SearchForm::Fields::Primitives::RadioButtonField, "without_inheritance_radio") }
    let(:checkbox_wrapper_double) { instance_double(SearchForm::Fields::Utilities::CheckboxGroupWrapper, "checkbox_wrapper") }
    let(:radio_wrapper_double) { instance_double(SearchForm::Fields::Utilities::RadioGroupWrapper, "radio_wrapper") }

    before do
      # The factory methods call `.with_form(form)`, which delegates to `form_state`.
      allow(form_state_double).to receive(:form)
      allow(form_state_double).to receive(:with_form)

      # Spy on the factory methods and wrappers to verify they are called correctly.
      allow(field).to receive(:create_multi_select_field).and_return(multi_select_double)
      allow(field).to receive(:create_all_checkbox).and_return(all_checkbox_double)
      allow(field).to receive(:create_radio_button_field).and_return(with_inheritance_radio_double,
                                                                     without_inheritance_radio_double)
      allow(SearchForm::Fields::Utilities::CheckboxGroupWrapper).to receive(:new).and_return(checkbox_wrapper_double)
      allow(SearchForm::Fields::Utilities::RadioGroupWrapper).to receive(:new).and_return(radio_wrapper_double)

      # Stub the private method that hits the DB to keep this test focused on composition.
      allow(field).to receive(:grouped_teachable_list).and_return([["Course A",
                                                                    [["Lecture 1", 1]]]])
    end

    it "calls create_multi_select_field with the correct arguments" do
      expected_args = {
        name: :teachable_ids,
        label: I18n.t("basics.associated_to"),
        help_text: I18n.t("search.fields.helpdesks.teachable_field"),
        collection: [["Course A", [["Lecture 1", 1]]]]
      }
      expect(field).to receive(:create_multi_select_field).with(hash_including(expected_args))
      field.before_render
    end

    it "calls create_all_checkbox with the correct stimulus configuration" do
      expected_stimulus = { toggle: true, toggle_radio_group: "teachable_inheritance",
                            default_radio_value: "1" }
      expect(field).to receive(:create_all_checkbox)
        .with(hash_including(for_field_name: :teachable_ids, stimulus: expected_stimulus))
      field.before_render
    end

    it "calls create_radio_button_field for the 'with inheritance' option" do
      expected_args = {
        name: :teachable_inheritance, value: "1", label: I18n.t("basics.with_inheritance"),
        checked: true, disabled: true, stimulus: { radio_toggle: true, controls_select: false }
      }
      expect(field).to receive(:create_radio_button_field).with(hash_including(expected_args)).once
      field.before_render
    end

    it "calls create_radio_button_field for the 'without inheritance' option" do
      expected_args = {
        name: :teachable_inheritance, value: "0", label: I18n.t("basics.without_inheritance"),
        checked: false, disabled: true, stimulus: { radio_toggle: true, controls_select: false }
      }
      expect(field).to receive(:create_radio_button_field).with(hash_including(expected_args)).once
      field.before_render
    end

    it "instantiates a CheckboxGroupWrapper and a RadioGroupWrapper" do
      expect(SearchForm::Fields::Utilities::CheckboxGroupWrapper).to receive(:new)
        .with(parent_field: multi_select_double, checkboxes: [all_checkbox_double])
      expect(SearchForm::Fields::Utilities::RadioGroupWrapper).to receive(:new)
        .with(name: :teachable_inheritance, parent_field: multi_select_double, radio_buttons: [
                with_inheritance_radio_double, without_inheritance_radio_double
              ])
      field.before_render
    end
  end

  describe "#grouped_teachable_list (private)" do
    # Use doubles to simulate the data returned from the database.
    # This isolates the test to only the transformation logic within the method.
    let(:lecture_a) { instance_double(Lecture, short_title: "Lecture 2", id: 1) }
    let(:lecture_c) { instance_double(Lecture, short_title: "Lecture 10", id: 3) }
    let(:lectures_relation_a) { double("lectures_relation_a") }
    let(:course_a) do
      instance_double(Course, title: "Course 2", short_title: "C2", id: 101,
                              lectures: lectures_relation_a)
    end

    let(:lecture_b) { instance_double(Lecture, short_title: "Lecture 1", id: 2) }
    let(:lectures_relation_b) { double("lectures_relation_b") }
    let(:course_b) do
      instance_double(Course, title: "Course 10", short_title: "Course 10", id: 102,
                              lectures: lectures_relation_b)
    end

    before do
      # Stub the entire query chain to return our controlled set of doubles.
      allow(Course).to receive_message_chain(:includes, :order)
        .with(:title).and_return([course_a, course_b])

      # Stub the .natural_sort_by call on the lectures relations.
      allow(lectures_relation_a).to receive(:natural_sort_by).and_return([lecture_a, lecture_c])
      allow(lectures_relation_b).to receive(:natural_sort_by).and_return([lecture_b])
    end

    it "returns a naturally sorted and correctly grouped list of teachables" do
      expected_collection = [
        [
          "Course 2", # Course A title
          [
            ["C2 #{I18n.t("basics.course")}", "Course-101"],
            ["Lecture 2", "Lecture-1"],
            ["Lecture 10", "Lecture-3"]
          ]
        ],
        [
          "Course 10", # Course B title
          [
            ["Course 10 #{I18n.t("basics.course")}", "Course-102"],
            ["Lecture 1", "Lecture-2"]
          ]
        ]
      ]

      # Call the private method using .send
      expect(field.send(:grouped_teachable_list)).to eq(expected_collection)
    end
  end
end
