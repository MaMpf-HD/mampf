require "rails_helper"

RSpec.describe("Dashboard::WashiTapes", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture) }

  before do
    sign_in user
  end

  def style
    Dashboard::CardStyle.find_by(user: user, lecture: lecture)
  end

  describe "PATCH /dashboard/washi_tape/:lecture_id" do
    context "when the user has bookmarked the lecture" do
      before do
        user.subscribe_lecture!(lecture)
      end

      it "saves the chosen color" do
        patch dashboard_washi_tape_path(lecture),
              params: { washi_tape: { tape_color: "mint" } }

        expect(response).to have_http_status(:no_content)
        expect(style.tape_color).to eq("mint")
      end

      it "replaces a color that was picked before" do
        Dashboard::CardStyle.create!(user: user, lecture: lecture,
                                     tape_color: "sky")

        patch dashboard_washi_tape_path(lecture),
              params: { washi_tape: { tape_color: "rose" } }

        expect(style.tape_color).to eq("rose")
        expect(Dashboard::CardStyle.where(user: user, lecture: lecture).count)
          .to eq(1)
      end

      it "rejects a color that does not exist" do
        patch dashboard_washi_tape_path(lecture),
              params: { washi_tape: { tape_color: "holographic" } }

        expect(response).to have_http_status(:unprocessable_content)
        expect(style).to be_nil
      end
    end

    it "styles a lecture the user holds a place in but has not bookmarked" do
      lecture.lecture_memberships.create!(user: user)

      patch dashboard_washi_tape_path(lecture),
            params: { washi_tape: { tape_color: "peach" } }

      expect(response).to have_http_status(:no_content)
      expect(style.tape_color).to eq("peach")
    end

    it "styles a lecture shown only through a pending registration application" do
      campaign = create(:registration_campaign, :open, campaignable: lecture)
      create(:registration_user_registration, :pending,
             user: user, registration_campaign: campaign,
             registration_item: campaign.registration_items.first)

      patch dashboard_washi_tape_path(lecture),
            params: { washi_tape: { tape_color: "peach" } }

      expect(response).to have_http_status(:no_content)
      expect(style.tape_color).to eq("peach")
    end

    it "styles a seminar the user gives a talk in" do
      seminar = create(:lecture, sort: "seminar")
      talk = create(:talk, lecture: seminar)
      talk.speakers << user

      patch dashboard_washi_tape_path(seminar),
            params: { washi_tape: { tape_color: "lavender" } }

      expect(response).to have_http_status(:no_content)
      expect(Dashboard::CardStyle.find_by(user: user, lecture: seminar)
                                 .tape_color).to eq("lavender")
    end

    it "refuses a lecture that is not on this user's dashboard" do
      patch dashboard_washi_tape_path(lecture),
            params: { washi_tape: { tape_color: "mint" } }

      expect(response).to have_http_status(:not_found)
      expect(style).to be_nil
    end

    it "redirects an unauthenticated request to sign in" do
      sign_out user

      patch dashboard_washi_tape_path(lecture),
            params: { washi_tape: { tape_color: "mint" } }

      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
