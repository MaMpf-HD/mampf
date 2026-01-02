require "rails_helper"

RSpec.describe("Registration::Policies", type: :request) do
  let(:lecture) { create(:lecture) }
  let(:editor) { create(:confirmed_user) }
  let(:student) { create(:confirmed_user) }
  let(:campaign) do
    create(:registration_campaign, campaignable: lecture, status: :draft)
  end

  before do
    Flipper.enable(:registration_campaigns)
    create(:editable_user_join, user: editor, editable: lecture)
  end

  describe "GET /campaigns/:campaign_id/policies/new" do
    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get new_registration_campaign_policy_path(campaign)
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get new_registration_campaign_policy_path(campaign)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when campaign does not exist" do
      before { sign_in editor }

      it "redirects to root with error" do
        get new_registration_campaign_policy_path(registration_campaign_id: -1)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("registration.campaign.not_found"))
      end
    end
  end

  describe "GET /campaigns/:campaign_id/policies/:id/edit" do
    let(:policy) do
      create(:registration_policy, registration_campaign: campaign,
                                   kind: :institutional_email)
    end

    context "as an editor" do
      before { sign_in editor }

      it "returns http success" do
        get edit_registration_campaign_policy_path(campaign, policy)
        expect(response).to have_http_status(:success)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get edit_registration_campaign_policy_path(campaign, policy)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when policy does not exist" do
      before { sign_in editor }

      it "redirects to campaign policies tab with error" do
        get edit_registration_campaign_policy_path(campaign, id: -1)
        expect(response).to redirect_to(registration_campaign_path(campaign,
                                                                   anchor: "policies-tab"))
        expect(flash[:alert]).to eq(I18n.t("registration.policy.not_found"))
      end
    end
  end

  describe "POST /campaigns/:campaign_id/policies" do
    let(:valid_attributes) do
      { kind: "institutional_email",
        phase: "registration",
        allowed_domains: "example.com, test.org" }
    end

    context "as an editor" do
      before { sign_in editor }

      it "creates a new policy" do
        expect do
          post(registration_campaign_policies_path(campaign),
               params: { registration_policy: valid_attributes })
        end.to change(Registration::Policy, :count).by(1)

        expect(response).to redirect_to(
          registration_campaign_path(campaign, anchor: "policies-tab")
        )
      end

      it "fails with invalid attributes" do
        expect do
          post(registration_campaign_policies_path(campaign),
               params: { registration_policy: { kind: "" } })
        end.not_to change(Registration::Policy, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      context "when campaign is not draft" do
        before do
          create(:registration_item, registration_campaign: campaign,
                                     registerable: create(:tutorial, lecture: lecture))
          campaign.update!(status: :open)
        end

        it "fails to create policy" do
          expect do
            post(registration_campaign_policies_path(campaign),
                 params: { registration_policy: valid_attributes })
          end.not_to change(Registration::Policy, :count)

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        post registration_campaign_policies_path(campaign),
             params: { registration_policy: valid_attributes }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /campaigns/:campaign_id/policies/:id" do
    let(:policy) do
      create(:registration_policy, registration_campaign: campaign,
                                   kind: :institutional_email,
                                   config: { "allowed_domains" => "old.com" })
    end
    let(:new_attributes) do
      { allowed_domains: "new.com, another.org" }
    end

    context "as an editor" do
      before { sign_in editor }

      it "updates the policy" do
        patch registration_campaign_policy_path(campaign, policy),
              params: { registration_policy: new_attributes }

        policy.reload
        expect(policy.allowed_domains).to eq("new.com, another.org")
        expect(response).to redirect_to(
          registration_campaign_path(campaign, anchor: "policies-tab")
        )
      end

      it "fails with invalid attributes" do
        patch registration_campaign_policy_path(campaign, policy),
              params: { registration_policy: { kind: "" } }

        expect(response).to have_http_status(:unprocessable_entity)
      end

      context "when campaign is not draft" do
        before do
          policy # ensure policy is created before campaign status update
          create(:registration_item, registration_campaign: campaign,
                                     registerable: create(:tutorial, lecture: lecture))
          campaign.update!(status: :open)
        end

        it "fails to update policy" do
          patch registration_campaign_policy_path(campaign, policy),
                params: { registration_policy: new_attributes }

          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch registration_campaign_policy_path(campaign, policy),
              params: { registration_policy: new_attributes }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "DELETE /campaigns/:campaign_id/policies/:id" do
    let!(:policy) do
      create(:registration_policy, registration_campaign: campaign,
                                   kind: :institutional_email)
    end

    context "as an editor" do
      before { sign_in editor }

      it "destroys the policy" do
        expect do
          delete(registration_campaign_policy_path(campaign, policy))
        end.to change(Registration::Policy, :count).by(-1)

        expect(response).to redirect_to(
          registration_campaign_path(campaign, anchor: "policies-tab")
        )
      end

      context "when campaign is not draft" do
        before do
          policy # ensure policy is created before campaign status update
          create(:registration_item, registration_campaign: campaign,
                                     registerable: create(:tutorial, lecture: lecture))
          campaign.update!(status: :open)
        end

        it "fails to destroy policy" do
          expect do
            delete(registration_campaign_policy_path(campaign, policy))
          end.not_to change(Registration::Policy, :count)

          expect(response).to redirect_to(
            registration_campaign_path(campaign, anchor: "policies-tab")
          )
        end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        delete registration_campaign_policy_path(campaign, policy)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /campaigns/:campaign_id/policies/:id/move_up" do
    let!(:policy1) do
      create(:registration_policy, registration_campaign: campaign,
                                   kind: :institutional_email, position: 1)
    end
    let!(:policy2) do
      create(:registration_policy, registration_campaign: campaign,
                                   kind: :institutional_email, position: 2)
    end

    context "as an editor" do
      before { sign_in editor }

      it "moves the policy up in order" do
        patch move_up_registration_campaign_policy_path(campaign, policy2)

        policy2.reload
        policy1.reload
        expect(policy2.position).to eq(1)
        expect(policy1.position).to eq(2)
        expect(response).to redirect_to(
          registration_campaign_path(campaign, anchor: "policies-tab")
        )
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch move_up_registration_campaign_policy_path(campaign, policy2)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /campaigns/:campaign_id/policies/:id/move_down" do
    let!(:policy1) do
      create(:registration_policy, registration_campaign: campaign,
                                   kind: :institutional_email, position: 1)
    end
    let!(:policy2) do
      create(:registration_policy, registration_campaign: campaign,
                                   kind: :institutional_email, position: 2)
    end

    context "as an editor" do
      before { sign_in editor }

      it "moves the policy down in order" do
        patch move_down_registration_campaign_policy_path(campaign, policy1)

        policy1.reload
        policy2.reload
        expect(policy1.position).to eq(2)
        expect(policy2.position).to eq(1)
        expect(response).to redirect_to(
          registration_campaign_path(campaign, anchor: "policies-tab")
        )
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        patch move_down_registration_campaign_policy_path(campaign, policy1)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
