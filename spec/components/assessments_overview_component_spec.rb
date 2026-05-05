require "rails_helper"

RSpec.describe(AssessmentsOverviewComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }

  describe "#assessments_tab_label" do
    it "returns assignments label for regular lectures" do
      component = described_class.new(lecture: lecture)
      expect(component.assessments_tab_label).to eq(
        I18n.t("assessment.tabs.assignments")
      )
    end

    it "returns talks label for seminars" do
      seminar = create(:lecture, :released_for_all,
                       teacher: teacher, sort: "seminar")
      component = described_class.new(lecture: seminar)
      expect(component.assessments_tab_label).to eq(
        I18n.t("assessment.tabs.talks")
      )
    end
  end
end