require "rails_helper"

RSpec.describe(Search::Filters::LectureScopeFilter, type: :filter) do
  describe "#call" do
    let(:user) { create(:confirmed_user) }
    let(:scope) { Medium.all }

    # -- Teachable & Media Setup (Bottom-up) --
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
    let!(:medium_on_custom_lesson) { create(:lesson_medium) }
    let!(:custom_lesson) { medium_on_custom_lesson.teachable }
    let!(:custom_lecture) { custom_lesson.lecture }
    let!(:medium_on_custom_lecture) do
      create(:lecture_medium, teachable: custom_lecture)
    end
    let!(:medium_on_unrelated_lecture) { create(:lecture_medium) }
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

    subject(:filtered_scope) { described_class.apply(scope: scope, params: params, user: user) }

    before do
      user.lectures << subscribed_lecture
    end

    context "when 'lecture_scope' is '0' or blank" do
      context "with a nil value" do
        let(:params) { { lecture_scope: nil } }
        it("returns the original scope") { expect(filtered_scope).to match_array(all_media) }
      end

      context "with a blank string" do
        let(:params) { { lecture_scope: "" } }
        it("returns the original scope") { expect(filtered_scope).to match_array(all_media) }
      end

      context "with '0'" do
        let(:params) { { lecture_scope: "0" } }
        it("returns the original scope") { expect(filtered_scope).to match_array(all_media) }
      end
    end

    context "when 'lecture_scope' is '1' (subscribed)" do
      let(:params) { { lecture_scope: "1" } }
      it "filters to media from the user's subscribed courses, lectures, and lessons" do
        expected_media = [
          medium_on_subscribed_course,
          medium_on_subscribed_lecture,
          medium_on_subscribed_lesson
        ]
        expect(filtered_scope).to match_array(expected_media)
      end
    end

    context "when 'lecture_scope' is '2' (custom)" do
      context "with specified lectures" do
        let(:params) { { lecture_scope: "2", media_lectures: [custom_lecture.id] } }
        it "filters to media from the specified lectures and their lessons" do
          expected_media = [
            medium_on_custom_lecture,
            medium_on_custom_lesson
          ]
          expect(filtered_scope).to match_array(expected_media)
        end
      end

      context "with blank 'media_lectures'" do
        let(:params) { { lecture_scope: "2", media_lectures: [] } }
        it("returns the original scope") { expect(filtered_scope).to match_array(all_media) }
      end
    end

    context "when 'lecture_scope' is an invalid value" do
      let(:params) { { lecture_scope: "invalid_option" } }
      it("returns the original scope") { expect(filtered_scope).to match_array(all_media) }
    end
  end
end
