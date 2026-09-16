require "rails_helper"

RSpec.describe(AchievementMarkingTableComponent, type: :component) do
  let(:teacher) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all, teacher: teacher) }
  let(:group) { create(:tutorial, lecture: lecture, title: "Monday group") }
  let(:achievement) { create(:achievement, :boolean, lecture: lecture) }

  def member(name, tutorial: group)
    user = create(:confirmed_user, name_in_tutorials: name)
    create(:lecture_membership, lecture: lecture, user: user)
    create(:tutorial_membership, tutorial: tutorial, user: user) if tutorial
    user
  end

  def row_of(page, name)
    page.css("tbody tr").find { |row| row["data-status-filter-name"] == name }
  end

  # Joining the lecture seeds a row on every criterion, in no group.
  def record(user, **attrs)
    achievement.assessment.assessment_participations.find_by!(user: user).update!(**attrs)
  end

  before { allow(vc_test_controller).to receive(:current_user).and_return(teacher) }

  around { |example| I18n.with_locale(:en) { example.run } }

  describe "a group's table" do
    let(:component) { described_class.new(achievement: achievement, grading_scope: group) }

    it "says so when the group has nobody in it" do
      render_inline(component)

      expect(rendered_content).to include(I18n.t("assessment.achievements.marking.no_members"))
    end

    # Joining the lecture seeded the rows in no group; the group's table hands
    # its members' blank rows to the group, and anybody without a row yet
    # gets one as the table is drawn.
    it "lists every member of the group with a row of their own, in the group" do
      ada = member("Ada")
      member("Grace")
      member("Nina", tutorial: create(:tutorial, lecture: lecture))
      achievement.assessment.assessment_participations.find_by(user: ada).destroy!

      page = render_inline(component)

      expect(page.css("tbody tr").pluck("data-status-filter-name")).to eq(["Ada", "Grace"])
      expect(page.css("tbody tr").pluck("id")).to all(start_with("achievement-participation-row-"))
      expect(achievement.assessment.assessment_participations.where(tutorial: group).count).to eq(2)
      expect(page.css("select[data-status-filter-target=tutorial]")).to be_empty
    end

    it "shows where each person stands and offers the value" do
      record(member("Ada"), grade_text: "pass")
      record(member("Grace"), grade_text: "fail")
      member("Nina")

      page = render_inline(component)

      expect(row_of(page, "Ada").text).to include(I18n.t("assessment.achievements.marking.met"))
      expect(row_of(page, "Grace").text)
        .to include(I18n.t("assessment.achievements.marking.not_met"))
      expect(row_of(page, "Nina").text)
        .to include(I18n.t("assessment.achievements.marking.unmarked"))
      expect(row_of(page, "Ada").css("select[name=grade] option[selected]").first["value"])
        .to eq("pass")
      expect(page.css("#pointing-summary").text.squish)
        .to eq("1 met · 1 not met · 1 not yet graded")
    end

    it "shows an excused person's row without a field, and the way back for the lecturer" do
      record(member("Ada"), status: :exempt, note: "Certificate")

      page = render_inline(component)

      expect(row_of(page, "Ada").text).to include(I18n.t("assessment.achievements.marking.exempt"))
      expect(row_of(page, "Ada").css("select[name=grade]")).to be_empty
      back = I18n.t("assessment.grading_exam.remove_exempt")
      expect(row_of(page, "Ada").css("a[aria-label='#{back}']")).to be_present
    end
  end

  describe "the lecture's table" do
    let(:component) { described_class.new(achievement: achievement, grading_scope: lecture) }

    it "lists every member group by group, those in no group last, with a group filter" do
      other = create(:tutorial, lecture: lecture, title: "Friday group")
      member("Nina", tutorial: other)
      member("Ada")
      member("Ola", tutorial: nil)

      page = render_inline(component)

      expect(page.css("tbody tr").pluck("data-status-filter-name")).to eq(["Nina", "Ada", "Ola"])
      expect(page.css("select[data-status-filter-target=tutorial] option").map { |o| o.text.strip })
        .to include("Monday group", "Friday group")
    end
  end

  describe "the value's field" do
    let(:component) { described_class.new(achievement: achievement, grading_scope: group) }

    it "is a number with the threshold over it for a numeric criterion" do
      achievement.update!(value_type: :numeric, threshold: 12)
      member("Ada")

      page = render_inline(component)

      expect(page.css("input[type=number][name=grade]")).to be_present
      expect(page.css("thead").text).to include("threshold 12")
    end

    it "is a number with a percent sign for a percentage criterion" do
      achievement.update!(value_type: :percentage, threshold: 75)
      member("Ada")

      page = render_inline(component)

      expect(page.css("input[type=number][name=grade][max='100']")).to be_present
      expect(page.css(".input-group-text").text).to include("%")
    end
  end
end
