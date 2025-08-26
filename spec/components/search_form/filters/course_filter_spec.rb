require "rails_helper"

RSpec.describe(SearchForm::Filters::CourseFilter, type: :component) do
  let(:user) { instance_double(User, "user") }
  let(:form_state) { instance_double(SearchForm::Services::FormState) }
  let(:form_builder) { instance_double(ActionView::Helpers::FormBuilder) }

  subject(:filter) do
    field_instance = described_class.new
    field_instance.form_state = form_state
    field_instance
  end

  before do
    # Stub I18n and database calls to make tests independent and fast.
    allow(I18n).to receive(:t).with("basics.courses").and_return("Courses")
    allow(I18n).to receive(:t).with("admin.tag.info.search_course").and_return("Help text")
    allow(I18n).to receive(:t).with("buttons.edited_courses").and_return("Edited Courses")
    allow(I18n).to receive(:t).with("basics.all").and_return("All")
    allow(I18n).to receive(:t).with("basics.select").and_return("Please select")
    allow(Course).to receive_message_chain(:order,
                                           :pluck).and_return([["Course A", 1], ["Course B", 2]])

    # Set up mocks for rendering.
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
      expect(filter.name).to eq(:course_ids)
      expect(filter.label).to eq("Courses")
      expect(filter.help_text).to eq("Help text")
      expect(filter.collection).to eq([["Course A", 1], ["Course B", 2]])
    end

    it "initializes the edited courses button state to hidden" do
      expect(filter.show_edited_courses_button?).to be(false)
    end
  end

  describe "#with_edited_courses_button" do
    it "sets the current user" do
      filter.with_edited_courses_button(user)
      expect(filter.instance_variable_get(:@current_user)).to eq(user)
    end

    it "sets the show_edited_courses_button flag to true" do
      filter.with_edited_courses_button(user)
      expect(filter.show_edited_courses_button?).to be(true)
    end

    it "populates the content slot" do
      # The `content` slot is a ViewComponent internal. We check its presence.
      expect(filter.content).to be_nil
      filter.with_edited_courses_button(user)
      expect(filter.content).not_to be_nil
    end

    it "returns self to allow for chaining" do
      expect(filter.with_edited_courses_button(user)).to eq(filter)
    end
  end

  describe "rendering" do
    context "when the edited courses button is not configured" do
      it "does not render the button area" do
        doc = Nokogiri::HTML(render_inline(filter).to_s)
        expect(doc.css("#tags-edited-courses")).to be_empty
      end
    end

    context "when the edited courses button is configured" do
      let(:edited_courses) do
        [
          instance_double(Course, id: 1),
          instance_double(Course, id: 5)
        ]
      end

      before do
        allow(user).to receive(:edited_courses).and_return(edited_courses)
        filter.with_edited_courses_button(user)
      end

      it "renders the button with the correct attributes" do
        doc = Nokogiri::HTML(render_inline(filter).to_s)
        button = doc.css("button#tags-edited-courses").first

        expect(button).not_to be_nil
        expect(button.text.strip).to eq("Edited Courses")
        expect(button["type"]).to eq("button")
        expect(button["class"]).to eq("btn btn-sm btn-outline-info")
      end

      it "renders the button with the correct data attributes" do
        doc = Nokogiri::HTML(render_inline(filter).to_s)
        button = doc.css("button#tags-edited-courses").first

        expect(button["data-courses"]).to eq("[1,5]")
        expect(button["data-action"]).to eq("click->search-form#fillCourses")
      end
    end
  end
end
