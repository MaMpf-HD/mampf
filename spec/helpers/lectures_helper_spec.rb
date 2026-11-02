require "rails_helper"

RSpec.describe(LecturesHelper, type: :helper) do
  describe "the notification about a new lecture" do
    around { |example| I18n.with_locale(:en) { example.run } }

    it "names the lecture's term" do
      lecture = create(:lecture)

      expect(helper.lecture_notification_item_details(lecture))
        .to include(lecture.term.to_label)
      expect(helper.lecture_notification_card_link(lecture))
        .to include(lecture.term.to_label)
    end

    it "names no term for a lecture without one" do
      lecture = create(:lecture, :term_independent)

      expect(helper.lecture_notification_item_details(lecture))
        .to eq(I18n.t("notifications.subscribe_lecture"))
    end
  end

  describe "#quick_access_lectures" do
    let(:user) { create(:confirmed_user) }
    let(:course) { create(:course) }

    it "lists a course's lectures with the newest term first" do
      summer = create(:term, :summer, year: 2025)
      winter = create(:term, :winter, year: 2025)
      older = create(:term, :winter, year: 2024)
      lectures = [summer, older, winter].map do |term|
        create(:lecture, course: course, term: term)
      end
      user.favorite_lectures << lectures

      expect(helper.quick_access_lectures(user))
        .to eq([lectures[2], lectures[0], lectures[1]])
    end
  end
end
