require "rails_helper"

RSpec.describe("Lectures::Memberships", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:tutorial) do
    create(:tutorial, lecture: lecture, title: "Mo 10", skip_campaigns: true,
                      self_materialization_mode: :add_and_remove)
  end

  # An open campaign with the group as its item. update_column skips the
  # check that a group only joins campaigns while its roster is empty.
  def hold_in_campaign(group)
    group.update_column(:skip_campaigns, false) # rubocop:disable Rails/SkipsModelValidations
    campaign = create(:registration_campaign, campaignable: lecture)
    create(:registration_item, registration_campaign: campaign, registerable: group)
    campaign.update!(status: :open)
  end

  before do
    lecture.add_user_to_roster!(user)
    tutorial.add_user_to_roster!(user)
    user.bookmark_lecture!(lecture)
    sign_in user
  end

  describe "the lecture home" do
    it "puts the lecture into the participation list, its dialog listing what leaving does" do
      get lecture_home_path(lecture)

      body = response.body.squish
      expect(CGI.unescapeHTML(body))
        .to include("#{lecture.sort_localized} · #{lecture.course.title}")
      expect(body).to include(%(data-bs-target="##{LeaveLectureComponent.dialog_id(lecture)}"))
      expect(body).to include(I18n.t("lecture_home.leave.consequences.groups", groups: "Mo 10"))
      expect(body).to include(%(action="#{lecture_membership_path(lecture)}"))
      expect(CGI.unescapeHTML(body)).to include(
        I18n.t("lecture_home.leave.confirmation_label",
               code: lecture.course.short_title.delete(" "))
      )
    end

    it "says in the dialog why the student cannot leave alone, without leaving" do
      hold_in_campaign(tutorial)

      get lecture_home_path(lecture)

      body = CGI.unescapeHTML(response.body.squish)
      expect(body).to include(I18n.t("lecture_home.leave.blockers.group_fixed", title: "Mo 10"))
      expect(body).to include(I18n.t("lecture_home.leave.contact"))
      expect(body).not_to include(%(action="#{lecture_membership_path(lecture)}"))
    end

    it "offers nothing to leave to someone without a place in the lecture" do
      sign_in create(:confirmed_user)

      get lecture_home_path(lecture)

      expect(response.body).not_to include(LeaveLectureComponent.dialog_id(lecture))
    end
  end

  describe "DELETE /lectures/:lecture_id/membership" do
    it "ends the participation and says so" do
      delete lecture_membership_path(lecture),
             params: { confirmation: " #{lecture.course.short_title.downcase} " }

      expect(response).to redirect_to(lecture_home_path(lecture))
      expect(flash[:notice])
        .to eq(I18n.t("lecture_home.leave.done", lecture: lecture.title_term_info_no_type))
      expect(lecture.members).not_to include(user)
      expect(tutorial.reload.members).not_to include(user)
    end

    it "says the student takes part no more when the staff removed them meanwhile" do
      Rosters::MaintenanceService.new.remove_user!(user, lecture, notify: false)

      delete lecture_membership_path(lecture),
             params: { confirmation: lecture.course.short_title }

      expect(response).to redirect_to(lecture_home_path(lecture))
      expect(flash[:notice])
        .to eq(I18n.t("lecture_home.leave.not_participating",
                      lecture: lecture.title_term_info_no_type))
      expect(user.reload.lectures).not_to include(lecture)
    end

    it "keeps the places without the short title typed" do
      delete lecture_membership_path(lecture), params: { confirmation: "nope" }

      expect(response).to redirect_to(lecture_home_path(lecture))
      expect(flash[:alert]).to eq(I18n.t("lecture_home.leave.not_confirmed"))
      expect(lecture.members).to include(user)
    end

    it "asks to try again when leaving ran into a deadlock twice" do
      allow(Rosters::UserPlaces).to receive(:new).and_raise(ActiveRecord::Deadlocked)

      delete lecture_membership_path(lecture),
             params: { confirmation: lecture.course.short_title }

      expect(response).to redirect_to(lecture_home_path(lecture))
      expect(flash[:alert]).to eq(I18n.t("lecture_home.leave.failed"))
      expect(lecture.members).to include(user)
    end

    it "keeps the places when a group may not be left" do
      hold_in_campaign(tutorial)

      delete lecture_membership_path(lecture),
             params: { confirmation: lecture.course.short_title }

      expect(response).to redirect_to(lecture_home_path(lecture))
      expect(flash[:alert]).to eq(I18n.t("lecture_home.leave.not_allowed"))
      expect(lecture.members).to include(user)
    end
  end
end
