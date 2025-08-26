require "rails_helper"

RSpec.describe(SearchForm::Filters::EditorFilter, type: :component) do
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }
  let(:user_relation) { double("User::ActiveRecord_Relation") }

  # Sample data that `pluck` would return.
  let(:user_data) do
    [
      [2, "Beta User", "Tutor B", "beta@example.com"],
      [1, "Alpha User", nil, "alpha@example.com"] # No tutorial name
    ]
  end

  subject(:filter) do
    field_instance = described_class.new
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub I18n calls from this class and its parent.
    allow(I18n).to receive(:t).with("basics.editors").and_return("Editors")
    allow(I18n).to receive(:t).with("admin.lecture.info.search_teacher").and_return("Help text")
    allow(I18n).to receive(:t).with("basics.all").and_return("All")
    allow(I18n).to receive(:t).with("basics.select").and_return("Please select")

    # Stub the database query chain.
    allow(User).to receive(:joins).with(:editable_user_joins).and_return(user_relation)
    allow(user_relation).to receive(:distinct).and_return(user_relation)
    allow(user_relation).to receive(:pluck).and_return(user_data)

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
      expect(filter.name).to eq(:editor_ids)
      expect(filter.label).to eq("Editors")
      expect(filter.help_text).to eq("Help text")
    end

    it "builds the collection by formatting and sorting the user data" do
      # The expected collection should be sorted alphabetically by the display name.
      expected_collection = [
        ["Alpha User (alpha@example.com)", 1],
        ["Tutor B (beta@example.com)", 2]
      ]
      expect(filter.collection).to eq(expected_collection)
    end
  end

  describe "collection generation logic" do
    it "uses the tutorial name when present" do
      formatted_user = filter.collection.find { |c| c[1] == 2 }
      expect(formatted_user.first).to eq("Tutor B (beta@example.com)")
    end

    it "uses the full name when tutorial name is not present" do
      formatted_user = filter.collection.find { |c| c[1] == 1 }
      expect(formatted_user.first).to eq("Alpha User (alpha@example.com)")
    end

    it "sorts the final list by display name" do
      # The `initialize` test already confirms the final sorted order.
      # This just re-verifies that the first item is "Alpha" and not "Beta".
      expect(filter.collection.first.first).to start_with("Alpha")
    end
  end
end
