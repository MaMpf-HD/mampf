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
      { description: "Tutorial Registration",
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

        expect(response).to redirect_to(registration_campaign_path(Registration::Campaign.last,
                                                                   tab: "items"))
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
    let(:new_attributes) { { description: "Updated Description" } }

    context "when campaign is draft" do
      before { sign_in editor }

      it "updates the campaign" do
        patch registration_campaign_path(campaign),
              params: { registration_campaign: new_attributes }
        campaign.reload
        expect(campaign.description).to eq("Updated Description")
        expect(response).to redirect_to(registration_campaign_path(campaign))
      end
    end

    context "when campaign is open" do
      let!(:campaign) { create(:registration_campaign, :open, campaignable: lecture) }

      before do
        sign_in editor
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

      it "allows updating non-frozen attributes (description)" do
        patch registration_campaign_path(campaign),
              params: { registration_campaign: { description: "New Description" } }

        expect(response).to redirect_to(registration_campaign_path(campaign))

        campaign.reload
        expect(campaign.description).to eq("New Description")
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

    context "when enabling planning_only with incompatible items" do
      let!(:tutorial) { create(:tutorial, lecture: lecture) }
      let!(:item) do
        create(:registration_item, registration_campaign: campaign, registerable: tutorial)
      end

      before { sign_in editor }

      it "fails validation and shows error" do
        patch registration_campaign_path(campaign),
              params: { registration_campaign: { planning_only: true } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body)
          .to include(I18n.t("activerecord.errors.models.registration/campaign.attributes" \
                             ".planning_only.incompatible_items"))
      end
    end
  end

  describe "Lifecycle Actions" do
    describe "PATCH /campaigns/:id/open" do
      context "as an editor" do
        before do
          sign_in editor
          create(:registration_item, registration_campaign: campaign)
        end

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
      let!(:campaign) { create(:registration_campaign, :open, campaignable: lecture) }

      context "as an editor" do
        before { sign_in editor }

        it "changes status from open to closed" do
          patch close_registration_campaign_path(campaign)

          campaign.reload
          expect(campaign).to be_closed
          expect(response).to redirect_to(registration_campaign_path(campaign))
        end

        it "updates registration_deadline if it is in the future" do
          expect(campaign.registration_deadline).to be > Time.current
          patch close_registration_campaign_path(campaign)
          campaign.reload
          expect(campaign.registration_deadline).to be_within(1.minute).of(Time.current)
        end

        it "does not update registration_deadline if it is in the past" do
          # rubocop: disable Rails/SkipsModelValidations
          campaign.update_columns(registration_deadline: 1.day.ago)
          # rubocop: enable Rails/SkipsModelValidations
          original_deadline = campaign.registration_deadline

          patch close_registration_campaign_path(campaign)
          campaign.reload
          expect(campaign.registration_deadline).to eq(original_deadline)
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
        let!(:campaign) { create(:registration_campaign, :open, campaignable: lecture) }

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
    let!(:campaign) do
      create(:registration_campaign, :closed, campaignable: lecture,
                                              registration_deadline: 1.week.from_now)
    end

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
