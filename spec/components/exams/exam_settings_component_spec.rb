require "rails_helper"

RSpec.describe(ExamSettingsComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }

  context "with an existing exam" do
    let(:exam) do
      create(:exam, :with_capacity, :with_date,
             lecture: lecture, location: "Room 101")
    end

    it "renders the exam summary" do
      render_inline(described_class.new(exam: exam))

      expect(rendered_content).to include(exam.title)
      expect(rendered_content).to include("Room 101")
      expect(rendered_content).to include(exam.capacity.to_s)
    end

    it "renders the delete button" do
      render_inline(described_class.new(exam: exam))

      expect(rendered_content).to include(I18n.t("basics.delete"))
    end
  end

  context "with a new exam" do
    let(:exam) { build(:exam, lecture: lecture) }

    it "renders the back button and heading" do
      render_inline(described_class.new(exam: exam))

      expect(rendered_content).to include(I18n.t("back"))
      expect(rendered_content).to include(I18n.t("assessment.new_exam"))
    end
  end
end