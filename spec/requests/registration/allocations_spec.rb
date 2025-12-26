require "rails_helper"

RSpec.describe("Registration::Allocations", type: :request) do
  let(:lecture) { create(:lecture) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let!(:campaign) { create(:registration_campaign, :closed, campaignable: lecture) }

  before do
    Flipper.enable(:registration_campaigns)
    create(:editable_user_join, user: editor, editable: lecture)
  end

  describe "GET /campaigns/:campaign_id/allocation" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get registration_campaign_allocation_path(campaign)
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get registration_campaign_allocation_path(campaign)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when campaign does not exist" do
      before { sign_in editor }

      it "redirects to root with error" do
        get registration_campaign_allocation_path(registration_campaign_id: -1)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("registration.campaign.not_found"))
      end
    end
  end

  describe "POST /campaigns/:campaign_id/allocation" do
    context "as an editor" do
      before { sign_in editor }

      it "triggers allocation service" do
        expect_any_instance_of(Registration::AllocationService).to receive(:allocate!)
        post registration_campaign_allocation_path(campaign)
        expect(response).to redirect_to(registration_campaign_allocation_path(campaign))
        expect(flash[:notice]).to be_present
      end

      context "when campaign is open" do
        let!(:campaign) { create(:registration_campaign, :open, campaignable: lecture) }

        it "does not trigger allocation" do
          expect_any_instance_of(Registration::AllocationService).not_to receive(:allocate!)
          post registration_campaign_allocation_path(campaign)
          expect(response).to redirect_to(registration_campaign_path(campaign))
          expect(flash[:alert]).to be_present
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        post registration_campaign_allocation_path(campaign)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /campaigns/:campaign_id/allocation/finalize" do
    context "as an editor" do
      before { sign_in editor }

      context "when guard checks pass" do
        before do
          allow_any_instance_of(Registration::FinalizationGuard)
            .to receive(:check)
            .and_return(Registration::FinalizationGuard::Result.new(success?: true))
        end

        it "finalizes the campaign" do
          patch finalize_registration_campaign_allocation_path(campaign)

          campaign.reload
          expect(campaign).to be_completed
          expect(response).to redirect_to(registration_campaign_path(campaign))
          expect(flash[:notice]).to be_present
        end
      end

      context "when guard checks fail" do
        before do
          allow_any_instance_of(Registration::FinalizationGuard)
            .to receive(:check).and_return(
              Registration::FinalizationGuard::Result.new(success?: false,
                                                          error_code: :wrong_status)
            )
        end

        it "does not finalize the campaign and shows error" do
          patch finalize_registration_campaign_allocation_path(campaign)

          campaign.reload
          expect(campaign).not_to be_completed
          expect(response).to redirect_to(registration_campaign_allocation_path(campaign))
          expect(flash[:alert]).to eq(I18n.t("registration.allocation.errors.wrong_status"))
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch finalize_registration_campaign_allocation_path(campaign)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
