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

    context "with conflicting registrations" do
      let(:tutorial) { create(:tutorial, lecture: lecture) }
      let(:conflicting_student) { create(:confirmed_user) }
      let!(:registration) do
        create(:registration_user_registration,
               registration_campaign: campaign,
               user: conflicting_student)
      end

      before do
        sign_in editor
        # Enroll student in an existing tutorial of the same lecture
        create(:tutorial_membership, tutorial: tutorial, user: conflicting_student)
      end

      it "identifies the conflict" do
        get registration_campaign_allocation_path(campaign)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t("registration.allocation.conflicts.title"))
        expect(response.body).to include(conflicting_student.name)
        expect(response.body).to include(tutorial.title)
      end
    end

    context "with configuration blockers" do
      let(:blocked_student) { create(:confirmed_user, email: "blocked@example.com") }

      before do
        sign_in editor

        create(:registration_user_registration,
               registration_campaign: campaign,
               user: blocked_student)

        policy = build(:registration_policy,
                       :institutional_email,
                       :for_finalization,
                       registration_campaign: campaign,
                       config: { "allowed_domains" => "" })
        policy.save!(validate: false)
      end

      it "tells the teacher to contact admins" do
        get registration_campaign_allocation_path(campaign)

        expect(response).to have_http_status(:success)
        expect(response.body)
          .to include(I18n.t("registration.allocation.errors.policy_violation_config_desc"))
        expect(response.body).not_to include("force the finalization")
      end
    end

    context "with user blockers" do
      let(:blocked_student) { create(:confirmed_user, email: "blocked@example.com") }
      let(:guard_result) do
        Registration::FinalizationGuard::Result.new(
          success?: false,
          error_code: :policy_violation,
          error_message: "blocked",
          violations: [
            {
              user_id: blocked_student.id,
              registration_id: registration.id,
              name: blocked_student.name,
              email: blocked_student.email,
              policy: "student_performance",
              classification: Registration::ScreeningService::CLASSIFICATION_BLOCKER,
              blocker_kind: Registration::ScreeningService::BLOCKER_KIND_USER
            }
          ]
        )
      end
      let!(:registration) do
        create(:registration_user_registration,
               registration_campaign: campaign,
               user: blocked_student)
      end

      before do
        sign_in editor
        allow_any_instance_of(Registration::AllocationDashboard)
          .to receive(:guard_result)
          .and_return(guard_result)
      end

      it "offers a visible reject-for-now action" do
        get registration_campaign_allocation_path(campaign)

        expect(response).to have_http_status(:success)
        expect(response.body)
          .to include(I18n.t("registration.user_registration.actions.defer_due_to_blocker"))
        expect(response.body)
          .to include(I18n.t("registration.allocation.errors.policy_violation_user_desc"))
      end
    end

    context "with projected FCFS auto rejections" do
      let!(:campaign) { create(:registration_campaign, campaignable: lecture) }
      let(:blocked_student) { create(:confirmed_user, email: "blocked@example.com") }
      let!(:item) do
        create(:registration_item, registration_campaign: campaign)
      end

      before do
        sign_in editor

        create(:registration_policy, :institutional_email,
               registration_campaign: campaign,
               phase: :finalization,
               config: { "allowed_domains" => "uni.edu" })

        campaign.update!(status: :closed)

        create(:registration_user_registration,
               registration_campaign: campaign,
               registration_item: item,
               user: blocked_student)
      end

      it "shows the automatic rejections warning" do
        get registration_campaign_allocation_path(campaign)

        expect(response).to have_http_status(:success)
        expect(response.body).to include(
          I18n.t(
            "registration.allocation.dashboard.finalization_status.auto_rejections_title"
          )
        )
        expect(response.body).to include(
          I18n.t(
            "registration.allocation.dashboard.finalization_status.auto_rejections_desc",
            count: 1
          )
        )
      end
    end
  end

  describe "POST /campaigns/:campaign_id/allocation" do
    context "as an editor" do
      before { sign_in editor }

      context "when campaign is closed and preference based" do
        let!(:campaign) do
          create(:registration_campaign,
                 :closed,
                 :preference_based,
                 campaignable: lecture)
        end

        it "triggers allocation service" do
          expect_any_instance_of(Registration::AllocationService).to receive(:allocate!)
          post registration_campaign_allocation_path(campaign)
          expect(response).to redirect_to(registration_campaign_allocation_path(campaign))
          expect(flash[:notice]).to be_present
          expect(flash[:notice]).to include("calculated")
        end

        it "redirects back to the dashboard when allocation is blocked by policies" do
          screening_result = Registration::ScreeningService::Result.new(
            violations: [
              {
                classification: Registration::ScreeningService::CLASSIFICATION_BLOCKER
              }
            ]
          )

          allow_any_instance_of(Registration::AllocationService)
            .to receive(:allocate!)
            .and_raise(Registration::AllocationService::BlockedError.new(screening_result))

          post registration_campaign_allocation_path(campaign)

          expect(response).to redirect_to(registration_campaign_allocation_path(campaign))
          expect(flash[:alert]).to eq(I18n.t("registration.allocation.errors.policy_violation"))
        end
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

      context "when campaign is processing and preference based" do
        let!(:campaign) do
          create(:registration_campaign,
                 :processing,
                 :preference_based,
                 campaignable: lecture)
        end

        it "allows recalculation" do
          expect_any_instance_of(Registration::AllocationService).to receive(:allocate!)

          post registration_campaign_allocation_path(campaign)

          expect(response).to redirect_to(registration_campaign_allocation_path(campaign))
          expect(flash[:notice]).to be_present
          expect(flash[:notice]).to include("calculated")
        end
      end

      context "when campaign is first come first served" do
        let!(:campaign) do
          create(:registration_campaign,
                 :closed,
                 :first_come_first_served,
                 campaignable: lecture)
        end

        it "rejects allocation and keeps the campaign closed" do
          post registration_campaign_allocation_path(campaign)

          campaign.reload
          expect(campaign).to be_closed
          expect(response).to redirect_to(registration_campaign_path(campaign))
          expect(flash[:alert]).to include("preference-based campaigns")
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
          expect(flash[:notice]).to eq(I18n.t("registration.campaign.finalized"))
        end

        it "folds the summary into the modal instead of flashing over it" do
          with_groups = create(:registration_campaign, :closed,
                               :first_come_first_served, :with_items,
                               campaignable: lecture, items_count: 2)
          allow_any_instance_of(Registration::Campaign)
            .to receive(:open_rejected_count).and_return(2)

          patch finalize_registration_campaign_allocation_path(with_groups),
                as: :turbo_stream

          expect(response.body).to include("self-service-modal")
          expect(response.body).to include(
            I18n.t("registration.campaign.finalization_summary.rejected", count: 2)
          )
          # no flash is prepended over the modal
          expect(response.body)
            .not_to match(/action="prepend"[^>]*target="flash-messages"/)
        end

        it "does not prompt for self-service when the campaign has no groups" do
          no_groups = create(:registration_campaign, :first_come_first_served,
                             campaignable: lecture, status: :closed,
                             registration_deadline: 1.day.ago)

          patch finalize_registration_campaign_allocation_path(no_groups),
                as: :turbo_stream

          expect(response.body).not_to include("self-service-modal")
        end

        it "includes only nonzero queue summaries" do
          allow_any_instance_of(Registration::Campaign)
            .to receive(:open_rejected_count).and_return(5)
          allow_any_instance_of(Registration::Campaign)
            .to receive_message_chain(:unassigned_users, :count).and_return(3)

          patch finalize_registration_campaign_allocation_path(campaign)

          expect(flash[:notice]).to eq(
            [
              I18n.t("registration.campaign.finalized"),
              I18n.t("registration.campaign.finalization_summary.rejected", count: 5),
              I18n.t("registration.campaign.finalization_summary.unassigned", count: 3),
              I18n.t("registration.campaign.finalization_summary.manual_addition")
            ].join(" ")
          )
        end

        it "redirects back to the dashboard when finalization is blocked under lock" do
          screening_result = Registration::ScreeningService::Result.new(
            violations: [
              {
                classification: Registration::ScreeningService::CLASSIFICATION_BLOCKER
              }
            ]
          )

          allow_any_instance_of(Registration::Campaign)
            .to receive(:finalize!)
            .and_raise(Registration::Campaign::FinalizationBlockedError.new(screening_result))

          patch finalize_registration_campaign_allocation_path(campaign)

          expect(response).to redirect_to(registration_campaign_allocation_path(campaign))
          expect(flash[:alert]).to eq(I18n.t("registration.allocation.errors.policy_violation"))
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
