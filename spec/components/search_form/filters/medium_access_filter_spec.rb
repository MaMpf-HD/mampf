require "rails_helper"

RSpec.describe(SearchForm::Filters::MediumAccessFilter, type: :component) do
  let(:options) { {} }
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

  subject(:filter) do
    field_instance = described_class.new(**options)
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub all I18n calls made by the component.
    allow(I18n).to receive(:t).with("basics.access_rights").and_return("Access Rights")
    allow(I18n).to receive(:t).with("access.irrelevant").and_return("Irrelevant")
    allow(I18n).to receive(:t).with("access.all").and_return("All")
    allow(I18n).to receive(:t).with("access.users").and_return("Users")
    allow(I18n).to receive(:t).with("access.subscribers").and_return("Subscribers")
    allow(I18n).to receive(:t).with("access.locked").and_return("Locked")
    allow(I18n).to receive(:t).with("access.unpublished").and_return("Unpublished")
    allow(I18n).to receive(:t).with("basics.select").and_return("Please select") # From parent

    # Set up mocks for rendering (needed for parent class).
    allow(form_state).to receive(:form).and_return(form_builder)
    allow(form_state).to receive(:with_form).and_return(form_state)
    allow(form_state).to receive(:label_for)
    allow(form_state).to receive(:element_id_for)
    allow(form_builder).to receive(:label)
    allow(form_builder).to receive(:select)
  end

  describe "#initialize" do
    it "initializes as a SelectField with correct, hard-coded options" do
      expect(filter.name).to eq(:access)
      expect(filter.label).to eq("Access Rights")
      expect(filter.selected).to eq("irrelevant")
    end

    it "builds the correct static collection" do
      expected_collection = [
        ["Irrelevant", "irrelevant"],
        ["All", "all"],
        ["Users", "users"],
        ["Subscribers", "subscribers"],
        ["Locked", "locked"],
        ["Unpublished", "unpublished"]
      ]
      expect(filter.collection).to eq(expected_collection)
    end

    context "with additional options" do
      let(:options) { { container_class: "custom-class" } }

      it "passes the additional options to the superclass" do
        expect(filter.container_class).to eq("custom-class")
      end
    end
  end
end
