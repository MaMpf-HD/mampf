require "rails_helper"

RSpec.describe("Registration::Campaigns", type: :request) do
  let(:lecture) { create(:lecture) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let(:admin) { create(:confirmed_user, admin: true) }

  let!(:campaign) { create(:registration_campaign, campaignable: lecture, status: :draft) }

  before do
    Flipper.enable(:registration_campaigns)
    create(:editable_user_join, user: editor, editable: lecture)
  end

  describe "GET /lectures/:lecture_id/campaigns" do
    context "as an editor" do
      before do
        sign_in editor
      end

      it "returns http success" do
        get lecture_registration_campaigns_path(lecture)
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get lecture_registration_campaigns_path(lecture)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /lectures/:lecture_id/campaigns" do
    let(:valid_attributes) do
      { title: "Tutorial Registration",
        allocation_mode: "first_come_first_served",
        registration_deadline: 1.week.from_now }
    end

    context "as an editor" do
      before { sign_in editor }

      it "creates a new campaign" do
        expect do
          post(lecture_registration_campaigns_path(lecture),
               params: { registration_campaign: valid_attributes })
        end.to change(Registration::Campaign, :count).by(1)

        expect(response).to redirect_to(registration_campaign_path(Registration::Campaign.last))
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        post lecture_registration_campaigns_path(lecture),
             params: { registration_campaign: valid_attributes }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /campaigns/:id" do
    let(:new_attributes) { { title: "Updated Title" } }

    context "when campaign is draft" do
      before { sign_in editor }

      it "updates the campaign" do
        patch registration_campaign_path(campaign),
              params: { registration_campaign: new_attributes }
        campaign.reload
        expect(campaign.title).to eq("Updated Title")
        expect(response).to redirect_to(registration_campaign_path(campaign))
      end
    end

    context "when campaign is open" do
      before do
        sign_in editor
        campaign.update!(status: :open)
      end

      it "prevents updating frozen attributes (allocation_mode)" do
        # allocation_mode should be frozen when open
        patch registration_campaign_path(campaign),
              params: { registration_campaign: { allocation_mode: "preference_based" } }

        # Should re-render edit with errors (Unprocessable Entity)
        expect(response).to have_http_status(:unprocessable_entity)

        campaign.reload
        expect(campaign.allocation_mode).not_to eq("preference_based")
      end

      it "allows updating non-frozen attributes (title)" do
        patch registration_campaign_path(campaign),
              params: { registration_campaign: { title: "New Title" } }

        expect(response).to redirect_to(registration_campaign_path(campaign))

        campaign.reload
        expect(campaign.title).to eq("New Title")
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch registration_campaign_path(campaign),
              params: { registration_campaign: new_attributes }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "Lifecycle Actions" do
    describe "PATCH /campaigns/:id/open" do
      context "as an editor" do
        before { sign_in editor }

        it "changes status from draft to open" do
          patch open_registration_campaign_path(campaign)

          campaign.reload
          expect(campaign).to be_open
          expect(response).to redirect_to(registration_campaign_path(campaign))
        end
      end

      context "as a student" do
        before { sign_in student }

        it "redirects to root (unauthorized)" do
          patch open_registration_campaign_path(campaign)
          expect(response).to redirect_to(root_path)
        end
      end
    end

    describe "PATCH /campaigns/:id/close" do
      before { campaign.update!(status: :open) }

      context "as an editor" do
        before { sign_in editor }

        it "changes status from open to closed" do
          patch close_registration_campaign_path(campaign)

          campaign.reload
          expect(campaign).to be_closed
          expect(response).to redirect_to(registration_campaign_path(campaign))
        end
      end

      context "as a student" do
        before { sign_in student }

        it "redirects to root (unauthorized)" do
          patch close_registration_campaign_path(campaign)
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end

  describe "DELETE /campaigns/:id" do
    context "as an editor" do
      before { sign_in editor }

      context "when campaign is draft" do
        it "destroys the campaign" do
          expect do
            delete(registration_campaign_path(campaign))
          end.to change(Registration::Campaign, :count).by(-1)

          expect(response).to redirect_to(lecture_registration_campaigns_path(lecture))
        end
      end

      context "when campaign is open" do
        before { campaign.update!(status: :open) }

        it "does not destroy the campaign" do
          expect do
            delete(registration_campaign_path(campaign))
          end.not_to change(Registration::Campaign, :count)

          expect(response).to redirect_to(registration_campaign_path(campaign))
          expect(flash[:alert]).to be_present
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        delete registration_campaign_path(campaign)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /campaigns/:id" do
    context "as an editor" do
      before { sign_in editor }

      it "shows the campaign" do
        get registration_campaign_path(campaign)
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get registration_campaign_path(campaign)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "GET /campaigns/:id/edit" do
    context "as an editor" do
      before { sign_in editor }

      it "renders the edit form" do
        get edit_registration_campaign_path(campaign)
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get edit_registration_campaign_path(campaign)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /campaigns/:id/reopen" do
    before { campaign.update!(status: :closed) }

    context "as an editor" do
      before { sign_in editor }

      it "changes status from closed to open" do
        patch reopen_registration_campaign_path(campaign)

        campaign.reload
        expect(campaign).to be_open
        expect(response).to redirect_to(registration_campaign_path(campaign))
      end

      context "when campaign is completed" do
        before { campaign.update!(status: :completed) }

        it "does not reopen the campaign" do
          patch reopen_registration_campaign_path(campaign)

          campaign.reload
          expect(campaign).to be_completed
          expect(response).to redirect_to(registration_campaign_path(campaign))
          expect(flash[:alert]).to be_present
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch reopen_registration_campaign_path(campaign)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
