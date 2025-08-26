require "rails_helper"

RSpec.describe(SearchForm::Filters::LectureScopeFilter, type: :component) do
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }
  let(:lecture_relation) { double("Lecture::ActiveRecord_Relation") }

  # Create mock lecture objects to simulate the result of the query.
  let(:lecture_b) { double("LectureB", title: "Beta Lecture", id: 2) }
  let(:lecture_a) { double("LectureA", title: "Alpha Lecture", id: 1) }
  let(:lectures) { [lecture_b, lecture_a] }

  subject(:filter) do
    field_instance = described_class.new
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub I18n calls.
    allow(I18n).to receive(:t).with("basics.lectures").and_return("Lectures")
    allow(I18n).to receive(:t).with("search.media.lectures").and_return("Help text")
    allow(I18n).to receive(:t).with("basics.select").and_return("Please select") # From parent

    # Stub the database query chain.
    allow(Lecture).to receive(:includes).with(:course, :term).and_return(lecture_relation)
    allow(lecture_relation).to receive(:map).and_return(lectures.map { |l| [l.title, l.id] })

    # Set up mocks for rendering (needed for parent class).
    allow(form_state).to receive(:form).and_return(form_builder)
    allow(form_state).to receive(:with_form).and_return(form_state)
    allow(form_state).to receive(:label_for)
    allow(form_state).to receive(:element_id_for)
    allow(form_builder).to receive(:label)
    allow(form_builder).to receive(:select)
  end

  describe "#initialize" do
    it "initializes as a MultiSelectField with correct options" do
      expect(filter.name).to eq(:lectures)
      expect(filter.label).to eq("Lectures")
      expect(filter.help_text).to eq("Help text")
    end

    it "builds the collection by sorting the lecture data" do
      expected_collection = [
        ["Alpha Lecture", 1],
        ["Beta Lecture", 2]
      ]
      expect(filter.collection).to eq(expected_collection)
    end

    it "initializes the radio group state to hidden" do
      expect(filter.show_radio_group?).to be(false)
    end
  end

  describe "configuration and hooks" do
    it "#with_lecture_options sets the show_radio_group flag to true" do
      filter.with_lecture_options
      expect(filter.show_radio_group?).to be(true)
    end

    it "#with_lecture_options returns self to allow for chaining" do
      expect(filter.with_lecture_options).to eq(filter)
    end

    it "#show_checkbox? always returns false" do
      expect(filter.show_checkbox?).to be(false)
    end
  end

  describe "#render_radio_group" do
    let(:radio_group_double) { instance_double(SearchForm::Controls::RadioGroup) }

    before do
      # Stub the RadioGroup component's instantiation.
      allow(SearchForm::Controls::RadioGroup).to receive(:new).and_return(radio_group_double)

      # THIS IS THE FIX:
      # Stub the render call to also yield the component instance to the block.
      allow(filter).to receive(:render).with(radio_group_double).and_yield(radio_group_double)
                                       .and_return("Radio Group HTML")

      # This generic stub is still useful for the test that *doesn't* set expectations.
      allow(radio_group_double).to receive(:add_radio_button)
    end

    context "when not configured" do
      it "returns nil" do
        expect(filter.render_radio_group).to be_nil
      end
    end

    context "when configured with #with_lecture_options" do
      before do
        filter.with_lecture_options
        # Stub I18n calls for the radio button labels.
        allow(I18n).to receive(:t).with("search.media.lecture_options.all").and_return("All")
        allow(I18n).to receive(:t).with("search.media.lecture_options.subscribed")
                                  .and_return("Subscribed")
        allow(I18n).to receive(:t).with("search.media.lecture_options.own_selection")
                                  .and_return("Own Selection")
      end

      it "initializes a RadioGroup with the correct parameters" do
        expect(SearchForm::Controls::RadioGroup).to receive(:new)
          .with(form_state: form_state, name: :lecture_option)
        filter.render_radio_group
      end

      it "adds the three radio buttons with the correct configurations" do
        expect(radio_group_double).to receive(:add_radio_button)
          .with(hash_including(value: "0",
                               label: "All", checked: true))
        expect(radio_group_double).to receive(:add_radio_button)
          .with(hash_including(value: "1",
                               label: "Subscribed", checked: false))
        expect(radio_group_double).to receive(:add_radio_button)
          .with(hash_including(value: "2",
                               label: "Own Selection", checked: false))
        filter.render_radio_group
      end

      it "returns the rendered HTML" do
        expect(filter.render_radio_group).to eq("Radio Group HTML")
      end
    end
  end
end
