# spec/components/search_form/filters/tag_filter_spec.rb
require "rails_helper"

RSpec.describe(SearchForm::Filters::TagFilter, type: :component) do
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

  subject(:filter) do
    field_instance = described_class.new
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub I18n calls
    allow(I18n).to receive(:t).with("basics.tags").and_return("Tags")
    allow(I18n).to receive(:t).with("admin.medium.info.search_tags").and_return("Help text")
    allow(I18n).to receive(:t).with("basics.select").and_return("Please select")
    allow(I18n).to receive(:t).with("basics.no_results").and_return("No results")
    allow(I18n).to receive(:t).with("basics.all").and_return("All") # From parent

    # Set up mocks for rendering (needed for parent class)
    allow(form_state).to receive(:form).and_return(form_builder)
    allow(form_state).to receive(:with_form).and_return(form_state)
    allow(form_state).to receive(:label_for)
    allow(form_state).to receive(:element_id_for)
    allow(form_builder).to receive(:label)
    allow(form_builder).to receive(:select)
    allow(form_builder).to receive(:check_box)
  end

  describe "#initialize" do
    it "initializes with correct base options and an empty collection" do
      expect(filter.name).to eq(:tag_ids)
      expect(filter.label).to eq("Tags")
      expect(filter.help_text).to eq("Help text")
      expect(filter.collection).to be_empty
    end

    it "merges AJAX-specific data attributes into the options" do
      data_options = filter.options[:data]
      expect(data_options[:ajax]).to be(true)
      expect(data_options[:model]).to eq("tag")
      expect(data_options[:placeholder]).to eq("Please select")
    end

    it "initializes the radio group state to hidden" do
      expect(filter.show_radio_group?).to be(false)
    end
  end

  describe "configuration and hooks" do
    it "#with_operator_radios sets the show_radio_group flag to true" do
      filter.with_operator_radios
      expect(filter.show_radio_group?).to be(true)
    end

    it "#with_operator_radios returns self to allow for chaining" do
      expect(filter.with_operator_radios).to eq(filter)
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

    context "when configured with #with_operator_radios" do
      before do
        filter.with_operator_radios
        allow(I18n).to receive(:t).with("basics.OR").and_return("OR")
        allow(I18n).to receive(:t).with("basics.AND").and_return("AND")
      end

      it "initializes a RadioGroup with the correct parameters" do
        expect(SearchForm::Controls::RadioGroup).to receive(:new)
          .with(form_state: form_state, name: :tag_operator)
        filter.render_radio_group
      end

      it "adds the 'OR' and 'AND' radio buttons" do
        expect(radio_group_double).to receive(:add_radio_button)
          .with(hash_including(value: "or",
                               label: "OR", checked: true))
        expect(radio_group_double).to receive(:add_radio_button)
          .with(hash_including(value: "and",
                               label: "AND", checked: false))
        filter.render_radio_group
      end

      it "returns the rendered HTML" do
        expect(filter.render_radio_group).to eq("Radio Group HTML")
      end
    end
  end

  describe "#all_toggle_data_attributes" do
    it "returns the correct hash of data attributes" do
      expected_data = {
        search_form_target: "allToggle",
        action: "change->search-form#toggleFromCheckbox change->search-form#toggleRadioGroup",
        toggle_radio_group: "tag_operator",
        default_radio_value: "or"
      }
      expect(filter.all_toggle_data_attributes).to eq(expected_data)
    end
  end
end
