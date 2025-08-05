require "rails_helper"

RSpec.describe(Search::Filters::LectureScopeFilter, type: :filter) do
  describe "#call" do
    let(:user) { create(:confirmed_user) }
    let(:scope) { Medium.all }

    # -- Teachable & Media Setup (Bottom-up) --
    # Create media and their associated teachables together to ensure valid associations.

    # 1. Subscribed hierarchy
    let!(:medium_on_subscribed_lesson) { create(:lesson_medium) }
    let!(:subscribed_lesson) { medium_on_subscribed_lesson.teachable }
    let!(:subscribed_lecture) { subscribed_lesson.lecture }
    let!(:subscribed_course) { subscribed_lecture.course }
    let!(:medium_on_subscribed_course) do
      create(:course_medium, teachable: subscribed_course)
    end
    let!(:medium_on_subscribed_lecture) do
      create(:lecture_medium, teachable: subscribed_lecture)
    end

    # 2. Custom hierarchy
    let!(:medium_on_custom_lesson) { create(:lesson_medium) }
    let!(:custom_lesson) { medium_on_custom_lesson.teachable }
    let!(:custom_lecture) { custom_lesson.lecture }
    let!(:medium_on_custom_lecture) do
      create(:lecture_medium, teachable: custom_lecture)
    end

    # 3. Unrelated items
    let!(:medium_on_unrelated_lecture) { create(:lecture_medium) }
    let!(:unrelated_lecture) { medium_on_unrelated_lecture.teachable }

    let(:all_media) do
      [
        medium_on_subscribed_course,
        medium_on_subscribed_lecture,
        medium_on_subscribed_lesson,
        medium_on_custom_lecture,
        medium_on_custom_lesson,
        medium_on_unrelated_lecture
      ]
    end

    before do
      # Subscribe the user to one lecture. The filter should find media related
      # to this lecture, its parent course, and its child lessons.
      user.lectures << subscribed_lecture
    end

    context "when 'lecture_scope' is '0' or blank" do
      it "returns the original scope for a nil value" do
        params = { lecture_scope: nil }
        filter = described_class.new(scope, params, user: user)
        expect(filter.call).to match_array(all_media)
      end

      it "returns the original scope for a blank string" do
        params = { lecture_scope: "" }
        filter = described_class.new(scope, params, user: user)
        expect(filter.call).to match_array(all_media)
      end

      it "returns the original scope for '0'" do
        params = { lecture_scope: "0" }
        filter = described_class.new(scope, params, user: user)
        expect(filter.call).to match_array(all_media)
      end
    end

    context "when 'lecture_scope' is '1' (subscribed)" do
      it "filters to media from the user's subscribed courses, lectures, and lessons" do
        params = { lecture_scope: "1" }
        filter = described_class.new(scope, params, user: user)
        expected_media = [
          medium_on_subscribed_course,
          medium_on_subscribed_lecture,
          medium_on_subscribed_lesson
        ]
        expect(filter.call).to match_array(expected_media)
      end
    end

    context "when 'lecture_scope' is '2' (custom)" do
      it "filters to media from the specified lectures and their lessons" do
        params = { lecture_scope: "2", media_lectures: [custom_lecture.id] }
        filter = described_class.new(scope, params, user: user)
        expected_media = [
          medium_on_custom_lecture,
          medium_on_custom_lesson
        ]
        expect(filter.call).to match_array(expected_media)
      end

      it "returns the original scope if 'media_lectures' is blank" do
        params = { lecture_scope: "2", media_lectures: [] }
        filter = described_class.new(scope, params, user: user)
        expect(filter.call).to match_array(all_media)
      end
    end

    context "when 'lecture_scope' is an invalid value" do
      it "returns the original scope" do
        params = { lecture_scope: "invalid_option" }
        filter = described_class.new(scope, params, user: user)
        expect(filter.call).to match_array(all_media)
      end
    end
  end
end
