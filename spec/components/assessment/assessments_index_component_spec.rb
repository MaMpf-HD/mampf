require "rails_helper"

RSpec.describe(AssessmentsIndexComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  context "with a lecture" do
    let(:lecture) { create(:lecture, teacher: teacher) }

    it "includes assignments" do
      create(:valid_assignment, lecture: lecture, title: "Assignment 1")
      component = described_class.new(lecture: lecture)
      render_inline(component)
      expect(rendered_content).to include("Assignment 1")
    end

    # One table needs no heading; two do, one each.
    it "lists tests in a table of their own, and names both tables then" do
      create(:valid_assignment, lecture: lecture, title: "Assignment 1")
      page = render_inline(described_class.new(lecture: lecture))
      expect(page.css("h6")).to be_empty

      create(:valid_assignment, lecture: lecture, title: "Test 1", kind: :test)
      page = render_inline(described_class.new(lecture: lecture))
      expect(page.css("h6").map(&:text)).to eq(["Homework", "Tests"])
      expect(page.css("#assessment-tests-list").text).to include("Test 1")
      expect(page.css("#assessment-assignments-list").text).not_to include("Test 1")
    end
  end

  context "with a seminar" do
    let(:seminar) { create(:lecture, sort: "seminar", teacher: teacher) }

    it "includes talks with speakers" do
      talk = create(:talk, lecture: seminar, title: "Talk 1")
      create(:speaker_talk_join, talk: talk)
      component = described_class.new(lecture: seminar)
      render_inline(component)
      expect(rendered_content).to include("Talk 1")
    end
  end
end
