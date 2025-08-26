# spec/components/search_form/filters/medium_type_filter_spec.rb
require "rails_helper"

RSpec.describe(SearchForm::Filters::MediumTypeFilter, type: :component) do
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

  # Set up different user types
  let(:admin_user) { instance_double(User, "admin", admin_or_editor?: true) }
  let(:regular_user) { instance_double(User, "regular_user", admin_or_editor?: false) }
  let(:current_user) { admin_user } # Default to admin

  # Set up different purposes
  let(:purpose) { "media" }
  let(:options) { { current_user: current_user, purpose: purpose } }

  # Stubbed collections
  let(:quizzables) { [["Question", "Question"]] }
  let(:importables) { [["Video", "Video"]] }
  let(:generic_sorts) { [["Image", "Image"]] }
  let(:all_sorts) { [["Quiz", "Quiz"], ["Video", "Video"]] }

  subject(:filter) do
    field_instance = described_class.new(**options)
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub I18n calls
    allow(I18n).to receive(:t).with("basics.types").and_return("Types")
    allow(I18n).to receive(:t).with("search.media.type").and_return("Help text")
    allow(I18n).to receive(:t).with("basics.all").and_return("All")
    allow(I18n).to receive(:t).with("basics.select").and_return("Please select")

    # Stub all possible collection methods on Medium
    allow(Medium).to receive(:select_quizzables).and_return(quizzables)
    allow(Medium).to receive(:select_importables).and_return(importables)
    allow(Medium).to receive(:select_generic).and_return(generic_sorts)
    allow(Medium).to receive(:select_sorts).and_return(all_sorts)

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
    it "initializes with correct base options" do
      expect(filter.name).to eq(:types)
      expect(filter.label).to eq("Types")
      expect(filter.help_text).to eq("Help text")
    end

    it "stores the purpose and current_user" do
      expect(filter.purpose).to eq(purpose)
      expect(filter.current_user).to eq(current_user)
    end
  end

  describe "purpose-driven behavior" do
    context "when purpose is 'media'" do
      let(:purpose) { "media" }

      it "is disabled" do
        expect(filter.options[:disabled]).to be(true)
      end

      it "is multiple select" do
        expect(filter.options[:multiple]).to be(true)
      end

      it "does not skip the 'All' checkbox" do
        expect(filter.skip_all_checkbox?).to be(false)
      end

      it "has no pre-selected value" do
        expect(filter.selected).to eq("")
      end

      context "with an admin user" do
        let(:current_user) { admin_user }
        it "uses the full collection" do
          expect(filter.collection).to eq(all_sorts)
        end
      end

      context "with a regular user" do
        let(:current_user) { regular_user }
        it "uses the generic collection" do
          expect(filter.collection).to eq(generic_sorts)
        end
      end
    end

    context "when purpose is 'import'" do
      let(:purpose) { "import" }

      it "is not disabled" do
        expect(filter.options[:disabled]).to be(false)
      end

      it "is multiple select" do
        expect(filter.options[:multiple]).to be(true)
      end

      it "skips the 'All' checkbox" do
        expect(filter.skip_all_checkbox?).to be(true)
      end

      it "uses the importable collection" do
        expect(filter.collection).to eq(importables)
      end
    end

    context "when purpose is 'quiz'" do
      let(:purpose) { "quiz" }

      it "is not disabled" do
        expect(filter.options[:disabled]).to be(false)
      end

      it "is single select" do
        expect(filter.options[:multiple]).to be(false)
      end

      it "skips the 'All' checkbox" do
        expect(filter.skip_all_checkbox?).to be(true)
      end

      it "uses the quizzable collection" do
        expect(filter.collection).to eq(quizzables)
      end

      it "pre-selects 'Question'" do
        expect(filter.selected).to eq("Question")
      end
    end
  end
end
