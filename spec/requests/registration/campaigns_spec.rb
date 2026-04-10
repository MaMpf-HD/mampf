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

      it "excludes exam-linked campaigns from the list" do
        exam = create(:exam, lecture: lecture)
        exam_campaign = exam.registration_campaign

        get lecture_registration_campaigns_path(lecture), as: :turbo_stream
        expect(response.body).to include(
          registration_campaign_path(campaign)
        )
        expect(response.body).not_to include(
          registration_campaign_path(exam_campaign)
        )
      end

      it "renders the turbo stream for index" do
        get lecture_registration_campaigns_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:ok)
      end
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get lecture_registration_campaigns_path(lecture)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when lecture does not exist" do
      before { sign_in editor }

      it "redirects to root with error" do
        get lecture_registration_campaigns_path(lecture_id: -1)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("registration.campaign.lecture_not_found"))
      end
    end
  end

  describe "GET /lectures/:lecture_id/campaigns/new" do
    context "as an editor" do
      before { sign_in editor }

      it "renders the turbo stream for new" do
        get new_lecture_registration_campaign_path(lecture_id: lecture.id), as: :turbo_stream
        expect(response).to have_http_status(:ok)
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

        new_campaign = Registration::Campaign.order(created_at: :desc).first
        expect(response).to redirect_to(
          registration_campaign_path(new_campaign)
        )
      end

      it "creates a campaign via turbo stream" do
        post lecture_registration_campaigns_path(lecture), params: {
          registration_campaign: valid_attributes
        }, as: :turbo_stream

        expect(response).to have_http_status(:ok)
        assert_turbo_stream action: :update, target: "campaigns_container"
      end

      context "with invalid parameters" do
        it "responds with form error" do
          post lecture_registration_campaigns_path(lecture), params: {
            registration_campaign: { description: nil }
          }, as: :turbo_stream

          expect(response).to have_http_status(:unprocessable_content)
          assert_turbo_stream action: :replace, target: "new_campaign_form"
        end
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
        expect(response).to have_http_status(:ok)
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

        expect(response).to have_http_status(:ok)

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

        context "when update_status fails" do
          before do
            allow_any_instance_of(Registration::Campaign).to receive(:update).and_return(false)
          end

          it "responds with error" do
            patch open_registration_campaign_path(campaign), as: :turbo_stream
            expect(response).to have_http_status(:ok)
            assert_flash_error
          end
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

        context "when update fails" do
          before do
            allow_any_instance_of(Registration::Campaign).to receive(:update).and_return(false)
          end

          it "responds with error turbo stream" do
            patch close_registration_campaign_path(campaign), as: :turbo_stream
            expect(response).to have_http_status(:ok)
            assert_flash_error
          end
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

        it "destroys the campaign via turbo stream" do
          delete registration_campaign_path(campaign), as: :turbo_stream

          expect(response).to have_http_status(:ok)
          assert_turbo_stream action: :update, target: "campaigns_container"
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

      context "when it cannot be deleted" do
        before do
          campaign.update!(status: :completed)
        end

        it "responds with error" do
          delete registration_campaign_path(campaign), as: :turbo_stream
          expect(response).to have_http_status(:ok)
          assert_flash_error
        end
      end

      context "when destroy fails internally" do
        before do
          allow_any_instance_of(Registration::Campaign)
            .to receive(:destroy).and_return(false)
          allow_any_instance_of(Registration::Campaign)
            .to receive(:can_be_deleted?).and_return(true)
        end

        it "responds with error" do
          delete registration_campaign_path(campaign), as: :turbo_stream
          expect(response).to have_http_status(:ok)
          assert_flash_error
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

      it "renders the turbo stream for show" do
        get registration_campaign_path(campaign), as: :turbo_stream
        expect(response).to have_http_status(:ok)
      end
    end

    context "as a student" do
      before { sign_in student }

      it "redirects to root (unauthorized)" do
        get registration_campaign_path(campaign)
        expect(response).to redirect_to(root_path)
      end
    end

    context "when campaign does not exist" do
      before { sign_in editor }

      it "redirects to root with error" do
        get registration_campaign_path(id: -1)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("registration.campaign.not_found"))
      end
    end
  end

  describe "GET /campaigns/:id/unassigned" do
    context "as an editor" do
      before { sign_in editor }

      context "without source=panel" do
        it "redirects to the lecture groups tab" do
          get unassigned_registration_campaign_path(campaign)
          expect(response).to redirect_to(edit_lecture_path(campaign.campaignable, tab: "groups"))
        end
      end

      context "with source=panel" do
        it "renders the roster side panel turbo stream" do
          get unassigned_registration_campaign_path(campaign),
              params: { source: "panel" }, as: :turbo_stream

          expect(response).to have_http_status(:ok)
          assert_turbo_stream action: :replace, target: "tutorial-roster-side-panel"
        end

        context "when a student remains on the lecture roster after losing their group" do
          let!(:campaign) do
            create(:registration_campaign, :completed, campaignable: lecture)
          end
          let(:sticky_student) { create(:confirmed_user, name: "Sticky Student") }
          let(:item) { campaign.registration_items.first }

          before do
            create(:registration_user_registration, :confirmed,
                   registration_campaign: campaign,
                   registration_item: item,
                   user: sticky_student)
            create(:lecture_membership, lecture: lecture, user: sticky_student)
          end

          it "still lists the student as unassigned" do
            get unassigned_registration_campaign_path(campaign),
                params: { source: "panel" }, as: :turbo_stream

            expect(response).to have_http_status(:ok)
            expect(response.body).to include("Sticky Student")
          end
        end
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

      context "when campaign is processing" do
        before do
          campaign.update!(status: :processing,
                           last_allocation_calculated_at: 1.hour.ago)
        end

        it "reopens the campaign to open" do
          patch reopen_registration_campaign_path(campaign),
                params: { registration_deadline: 1.week.from_now }

          campaign.reload
          expect(campaign).to be_open
        end

        it "resets allocation results" do
          item = campaign.registration_items.first
          user = create(:confirmed_user)
          create(:registration_user_registration,
                 registration_campaign: campaign, registration_item: item,
                 user: user, status: :confirmed)

          patch reopen_registration_campaign_path(campaign),
                params: { registration_deadline: 1.week.from_now }

          campaign.reload
          expect(campaign.last_allocation_calculated_at).to be_nil
          expect(campaign.user_registrations.confirmed).to be_empty
          expect(campaign.user_registrations.pending.count).to eq(1)
        end
      end

      context "when transaction raises ActiveRecord::RecordInvalid" do
        before do
          allow_any_instance_of(Registration::Campaign)
            .to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
        end

        it "rescues and responds with error stream" do
          patch reopen_registration_campaign_path(campaign), as: :turbo_stream
          expect(response).to have_http_status(:ok)
          assert_flash_error
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
  describe "exam campaign context" do
    let(:exam) { create(:exam, lecture: lecture) }
    let(:exam_campaign) { exam.registration_campaign }
    let(:frame_id) { "exam_#{exam.id}_registration" }

    before { sign_in editor }

    it "renders exam-specific partial on open with frame_id" do
      patch open_registration_campaign_path(exam_campaign),
            params: { frame_id: frame_id },
            as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(frame_id)
    end

    it "renders default partial on open without frame_id" do
      patch open_registration_campaign_path(exam_campaign),
            as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("campaigns_container")
    end

    it "renders exam-specific partial on close with frame_id" do
      exam_campaign.update!(status: :open)

      patch close_registration_campaign_path(exam_campaign),
            params: { frame_id: frame_id },
            as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(frame_id)
    end

    it "renders exam-specific partial on reopen with frame_id" do
      exam_campaign.update!(status: :closed)

      patch reopen_registration_campaign_path(exam_campaign),
            params: { frame_id: frame_id },
            as: :turbo_stream

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(frame_id)
    end
  end
end
