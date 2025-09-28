require "rails_helper"

RSpec.describe(SearchForm::Fields::LectureScopeField, type: :component) do
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
    let(:all_radio_double) { instance_double(SearchForm::Fields::Primitives::RadioButtonField, "all_radio") }
    let(:subscribed_radio_double) { instance_double(SearchForm::Fields::Primitives::RadioButtonField, "subscribed_radio") }
    let(:own_selection_radio_double) { instance_double(SearchForm::Fields::Primitives::RadioButtonField, "own_selection_radio") }
    let(:wrapper_double) { instance_double(SearchForm::Fields::Utilities::RadioGroupWrapper, "wrapper") }

    before do
      # The factory methods call `.with_form(form)`, which delegates to `form_state`.
      allow(form_state_double).to receive(:form)
      allow(form_state_double).to receive(:with_form)

      # Spy on the factory methods and wrapper to verify they are called correctly.
      allow(field).to receive(:create_multi_select_field).and_return(multi_select_double)
      allow(field).to receive(:create_radio_button_field)
        .and_return(all_radio_double, subscribed_radio_double, own_selection_radio_double)
      allow(SearchForm::Fields::Utilities::RadioGroupWrapper).to receive(:new)
        .and_return(wrapper_double)

      # Stub the private method that hits the DB to keep this test focused on composition.
      allow(field).to receive(:lecture_options).and_return([["Lecture A", 1]])
    end

    it "calls create_multi_select_field with the correct arguments" do
      expected_args = {
        name: :lectures,
        label: I18n.t("basics.lectures"),
        help_text: I18n.t("search.helpdesks.lecture_scope_field"),
        collection: [["Lecture A", 1]]
      }
      expect(field).to receive(:create_multi_select_field).with(hash_including(expected_args))
      field.before_render
    end

    it "calls create_radio_button_field for the 'All' option" do
      expected_args = {
        name: :lecture_option, value: "0",
        label: I18n.t("search.radio_buttons.lecture_scope_field.all"),
        checked: true, stimulus: { radio_toggle: true, controls_select: false }
      }
      expect(field).to receive(:create_radio_button_field).with(hash_including(expected_args)).once
      field.before_render
    end

    it "calls create_radio_button_field for the 'Subscribed' option" do
      expected_args = {
        name: :lecture_option, value: "1",
        label: I18n.t("search.radio_buttons.lecture_scope_field.subscribed"),
        checked: false, stimulus: { radio_toggle: true, controls_select: false }
      }
      expect(field).to receive(:create_radio_button_field).with(hash_including(expected_args)).once
      field.before_render
    end

    it "calls create_radio_button_field for the 'Own Selection' option" do
      expected_args = {
        name: :lecture_option, value: "2",
        label: I18n.t("search.radio_buttons.lecture_scope_field.own_selection"),
        checked: false, stimulus: { radio_toggle: true, controls_select: true }
      }
      expect(field).to receive(:create_radio_button_field).with(hash_including(expected_args)).once
      field.before_render
    end

    it "instantiates a RadioGroupWrapper with the created fields" do
      expect(SearchForm::Fields::Utilities::RadioGroupWrapper).to receive(:new)
        .with(
          name: :lecture_option,
          parent_field: multi_select_double,
          radio_buttons: [all_radio_double, subscribed_radio_double, own_selection_radio_double]
        )
      field.before_render
    end

    it "passes through additional options to the multi-select field" do
      field_with_options = described_class.new(**minimal_args, disabled: true)
      allow(field_with_options).to receive(:create_multi_select_field)
        .and_return(multi_select_double)
      allow(field_with_options).to receive(:form_state).and_return(form_state_double)

      expect(field_with_options).to receive(:create_multi_select_field)
        .with(hash_including(disabled: true))

      field_with_options.before_render
    end
  end

  describe "#lecture_options (private)" do
    let!(:lecture_b) { create(:lecture, course: create(:course, title: "Lecture 10")) }
    let!(:lecture_a) { create(:lecture, course: create(:course, title: "Lecture 2")) }

    it "returns a naturally sorted list of lectures" do
      # Stub the title method to return a predictable value.
      # Using `and_return` with a block gives access to the instance (`lecture`).
      allow_any_instance_of(Lecture).to receive(:title) do |lecture|
        lecture.course.title
      end

      expected_collection = [
        ["Lecture 2", lecture_a.id],
        ["Lecture 10", lecture_b.id]
      ]

      # Call the private method using .send
      expect(field.send(:lecture_options)).to eq(expected_collection)
    end
  end
end
