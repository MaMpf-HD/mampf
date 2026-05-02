require "rails_helper"

RSpec.describe("Registration::UserRegistrations", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, teacher: user) }
  let(:campaign) { create(:registration_campaign, campaignable: lecture) }
  let(:student) { create(:confirmed_user) }
  let!(:registration) do
    create(:registration_user_registration, registration_campaign: campaign, user: student)
  end

  before do
    Flipper.enable(:registration_campaigns)
    sign_in user
  end

  describe "DELETE /campaigns/:campaign_id/registrations/user/:user_id/reject" do
    let(:path) do
      reject_for_user_registration_campaign_registrations_path(campaign, user_id: student.id)
    end

    it "rejects the registration instead of deleting it" do
      expect do
        delete(path, headers: { "Accept" => "text/vnd.turbo-stream.html" })
      end.not_to change(Registration::UserRegistration, :count)

      expect(registration.reload).to be_rejected
      expect(registration.rejection_reason_type).to eq("manual")
      expect(registration.rejection_reason_code).to eq("withdrawn_by_teacher")
    end

    it "returns success via turbo stream" do
      delete path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq(Mime[:turbo_stream])
    end

    it "rerenders the exam registration tab when called from the exam registrations table" do
      exam = create(:exam, :with_date, lecture: lecture)
      exam_campaign = exam.registration_campaign
      exam_campaign.update!(status: :closed)
      exam_registration = create(
        :registration_user_registration,
        registration_campaign: exam_campaign,
        registration_item: exam_campaign.registration_items.first,
        user: student
      )

      delete(
        reject_for_user_registration_campaign_registrations_path(
          exam_campaign,
          user_id: student.id,
          source: "registrations"
        ),
        headers: { "Accept" => "text/vnd.turbo-stream.html" }
      )

      expect(response).to have_http_status(:success)
      expect(response.body).to include(%(target="exam_#{exam.id}_registration"))
      expect(response.body).to include(
        I18n.t("assessment.registration_tab.rejected_heading")
      )
      expect(response.body).to include(student.email)
      expect(response.body).not_to include(
        reject_for_user_registration_campaign_registrations_path(
          exam_campaign,
          user_id: student.id,
          source: "registrations"
        )
      )
      expect(exam_registration.reload).to be_rejected
    end

    context "when user is not authorized" do
      let(:other_user) { create(:confirmed_user) }

      before do
        sign_in other_user
      end

      it "does not destroy the registration" do
        expect do
          delete(path, headers: { "Accept" => "text/vnd.turbo-stream.html" })
        end.not_to change(Registration::UserRegistration, :count)
      end

      it "redirects to root" do
        delete path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to redirect_to(root_path)
      end
    end

    context "when campaign does not exist" do
      let(:path) do
        reject_for_user_registration_campaign_registrations_path(registration_campaign_id: -1,
                                                                 user_id: student.id)
      end

      it "redirects to root with error" do
        delete path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("registration.campaign.not_found"))
      end
    end

    context "when campaign is completed" do
      before do
        campaign.update!(status: :completed)
      end

      it "does not destroy the registration" do
        expect do
          delete(path, headers: { "Accept" => "text/vnd.turbo-stream.html" })
        end.not_to change(Registration::UserRegistration, :count)
      end

      it "shows error message" do
        delete path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.body).to include(I18n.t("registration.campaign.errors.already_finalized"))
      end
    end
  end
end
