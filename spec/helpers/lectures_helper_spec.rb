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
end
