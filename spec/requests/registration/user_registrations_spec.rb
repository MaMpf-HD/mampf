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

  describe "DELETE /campaigns/:campaign_id/registrations/user/:user_id" do
    let(:path) do
      destroy_for_user_registration_campaign_registrations_path(campaign, user_id: student.id)
    end

    it "rejects the registration without deleting it" do
      expect do
        delete(path, headers: { "Accept" => "text/vnd.turbo-stream.html" })
      end.not_to change(Registration::UserRegistration, :count)

      expect(registration.reload.status).to eq("rejected")
    end

    it "writes a teacher rejection status event" do
      expect do
        delete(path, headers: { "Accept" => "text/vnd.turbo-stream.html" })
      end.to change(Registration::StatusEvent, :count).by(1)

      event = Registration::StatusEvent.order(:created_at).last
      expect(event.registration).to eq(registration)
      expect(event.registration_campaign).to eq(campaign)
      expect(event.action).to eq(Registration::StatusEvent::ACTION_TEACHER_REJECT)
      expect(event.reason_type).to eq(Registration::StatusEvent::REASON_TYPE_MANUAL)
      expect(event.reason_code)
        .to eq(Registration::StatusEvent::REASON_CODE_WITHDRAWN_BY_TEACHER)
      expect(event.actor).to eq(user)
      expect(event.correlation_id).to be_present
      expect(event.snapshot).to include(
        "label" => "Manually rejected by teacher",
        "actor_name" => user.info,
        "student_name" => student.info
      )
    end

    it "returns success via turbo stream" do
      delete path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq(Mime[:turbo_stream])
    end

    context "when user is not authorized" do
      let(:other_user) { create(:confirmed_user) }

      before do
        sign_in other_user
      end

      it "does not reject the registration" do
        expect do
          delete(path, headers: { "Accept" => "text/vnd.turbo-stream.html" })
        end.not_to change(Registration::UserRegistration, :count)

        expect(registration.reload.status).to eq("pending")
      end

      it "redirects to root" do
        delete path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to redirect_to(root_path)
      end
    end

    context "when campaign does not exist" do
      let(:path) do
        destroy_for_user_registration_campaign_registrations_path(registration_campaign_id: -1,
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

      it "does not reject the registration" do
        expect do
          delete(path, headers: { "Accept" => "text/vnd.turbo-stream.html" })
        end.not_to change(Registration::UserRegistration, :count)

        expect(registration.reload.status).to eq("pending")
      end

      it "shows error message" do
        delete path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response.body).to include(I18n.t("registration.campaign.errors.already_finalized"))
      end
    end

    context "with a preference-based campaign bundle" do
      let(:campaign) { create(:registration_campaign, :preference_based, campaignable: lecture) }
      let!(:item1) { create(:registration_item, registration_campaign: campaign) }
      let!(:item2) { create(:registration_item, registration_campaign: campaign) }
      let!(:registration) do
        create(:registration_user_registration,
               :preference_based,
               registration_campaign: campaign,
               registration_item: item1,
               user: student,
               preference_rank: 1)
      end
      let!(:second_registration) do
        create(:registration_user_registration,
               :preference_based,
               registration_campaign: campaign,
               registration_item: item2,
               user: student,
               preference_rank: 2)
      end

      it "rejects the whole registration bundle with one correlation id" do
        expect do
          delete(path, headers: { "Accept" => "text/vnd.turbo-stream.html" })
        end.to change(Registration::StatusEvent, :count).by(2)

        expect(registration.reload.status).to eq("rejected")
        expect(second_registration.reload.status).to eq("rejected")

        events = Registration::StatusEvent.where(registration_campaign: campaign)
        expect(events.map(&:registration_id))
          .to contain_exactly(registration.id, second_registration.id)
        expect(events.map(&:correlation_id).uniq.size).to eq(1)
      end
    end

    context "when the user bundle is already rejected" do
      before do
        registration.update!(status: :rejected)
      end

      it "is a clean no-op and does not write another event" do
        expect do
          delete(path, headers: { "Accept" => "text/vnd.turbo-stream.html" })
        end.not_to change(Registration::StatusEvent, :count)

        expect(response).to redirect_to(registration_campaign_path(campaign))
        expect(flash[:alert]).to eq(I18n.t("registration.user_registration.none"))
      end
    end
  end
end
