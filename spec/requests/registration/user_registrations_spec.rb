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
      expect(registration.rejection_reason_label)
        .to eq(I18n.t("registration.user_registration.reason_labels.withdrawn_by_teacher"))
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

      it "does not destroy the registration" do
        expect do
          delete(path, headers: { "Accept" => "text/vnd.turbo-stream.html" })
        end.not_to change(Registration::UserRegistration, :count)
      end

      it "redirects to root" do
        delete path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to redirect_to(root_path)
      end

      it "denies before the completed-campaign probe (no membership oracle)" do
        campaign.update!(status: :completed)
        delete path, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to redirect_to(root_path)
        expect(response.body)
          .not_to include(I18n.t("registration.campaign.errors.already_finalized"))
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

RSpec.describe("Registration::UserRegistrations", type: :request) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture, :released_for_all) }
  let(:seminar) { create(:lecture, :is_seminar, :released_for_all) }
  let(:stub_success) { UserRegistrations::Handler::Result.new(true, []) }

  before do
    Flipper.enable(:registration_campaigns)
    create(:lecture_user_join, user: user, lecture: lecture)
    create(:lecture_user_join, user: user, lecture: seminar)
    sign_in user
  end

  describe "lecture registration routes" do
    it "uses the /home lecture path for registration" do
      expect(lecture_home_path(lecture)).to eq("/lectures/#{lecture.id}/home")
    end
  end

  describe "GET lecture home page (access)" do
    it "is accessible for students who are not subscribed and offers them " \
       "the subscription page" do
      unsubscribed_student = create(:confirmed_user)
      sign_in unsubscribed_student

      get lecture_home_path(lecture)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("lecture-home-subscribe-button")
      expect(response.body).to include(subscribe_lecture_path)
    end

    it "greys out every sidebar entry except Home for unsubscribed students" do
      unsubscribed_student = create(:confirmed_user)
      sign_in unsubscribed_student

      get lecture_home_path(lecture)

      expect(response).to have_http_status(:ok)

      sidebar_html = Nokogiri::HTML.fragment(response.body)
      sidebar_items = sidebar_html.css("#sidebar .sidebar-item")

      expect(sidebar_items.first["class"]).not_to include("disabled")
      expect(sidebar_items.drop(1)).to all(satisfy do |item|
        item["class"].include?("disabled")
      end)
    end

    it "shows a passphrase field for passphrase-protected lectures" do
      passphrase_lecture = create(:lecture, :released_for_all,
                                  passphrase: "secret")
      unsubscribed_student = create(:confirmed_user)
      sign_in unsubscribed_student

      get lecture_home_path(passphrase_lecture)

      expect(response.body).to include("lecture-home-passphrase")
    end

    it "does not show a passphrase field to roster members" do
      passphrase_lecture = create(:lecture, :released_for_all,
                                  passphrase: "secret")
      member = create(:confirmed_user)
      create(:lecture_membership, user: member, lecture: passphrase_lecture)
      sign_in member

      get lecture_home_path(passphrase_lecture)

      expect(response.body).to include("lecture-home-subscribe-button")
      expect(response.body).not_to include("lecture-home-passphrase")
    end

    it "is accessible for students without the passphrase" do
      passphrase_lecture = create(:lecture, :released_for_all,
                                  passphrase: "secret")

      get lecture_home_path(passphrase_lecture)

      expect(response).to have_http_status(:ok)
    end

    it "is accessible for the teacher of the lecture" do
      teacher_lecture = create(:lecture, teacher: user)

      get lecture_home_path(teacher_lecture)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET lectures/:lecture_id/campaign_registrations" do
    context "open + first-come-first-served tutorial campaign" do
      let(:campaign) do
        FactoryBot.create(:registration_campaign,
                          :first_come_first_served,
                          :open,
                          :with_policies,
                          campaignable: lecture,
                          description: "Solver Test Campaign")
      end
      it "return success response" do
        campaign
        get lecture_home_path(lecture)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="student_registration_options"')
      end

      it "renders available options" do
        campaign
        get lecture_home_path(lecture)
        expect(response.body.squish).to include("Solver Test Campaign")
      end
    end

    context "completed campaign" do
      let(:campaign) do
        FactoryBot.create(:registration_campaign, :first_come_first_served,
                          :completed,
                          campaignable: seminar,
                          description: "Solver Test Campaign")
      end
      it "return success response" do
        get lecture_home_path(seminar)
        expect(campaign.campaignable_type).to eq("Lecture")
        expect(response).to have_http_status(:ok)
      end
    end

    context "when no registration options are available" do
      it "renders the empty registration state" do
        get lecture_home_path(lecture)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('id="student_registration_options"')
        expect(response.body.squish).to include(
          I18n.t("roster.self_enrollment.no_registration_options")
        )
      end
    end

    context "when self-rosterization options are available without campaigns" do
      before do
        create(:tutorial,
               lecture: lecture,
               title: "Tutorial 7",
               skip_campaigns: true,
               self_materialization_mode: :add_only)
      end

      it "does not show the empty state message" do
        get lecture_home_path(lecture)

        expect(response).to have_http_status(:ok)
        expect(response.body.squish).to include("Tutorial 7")
        expect(response.body.squish).not_to include(
          I18n.t("roster.self_enrollment.no_registration_options")
        )
      end
    end

    context "when the user has submitted preferences but is not yet rosterized" do
      before do
        campaign = create(:registration_campaign, :preference_based, :open,
                          campaignable: lecture)

        create(:registration_user_registration,
               user: user,
               registration_campaign: campaign,
               registration_item: campaign.registration_items.first,
               preference_rank: 1,
               status: :pending)
      end

      it "shows that they will be assigned after the registration period" do
        get lecture_home_path(lecture)

        expect(response.body.squish).to include(
          I18n.t("registration.user_registration.index.pending_preference_notice")
        )
        expect(response.body).to include("student-registration-rosterized-notice--neutral")
      end
    end

    context "when the user is already rosterized" do
      before do
        tutorial = create(:tutorial, lecture: lecture, title: "Tutorial 2")
        create(:tutorial_membership, tutorial: tutorial, user: user)
      end

      it "does not show the empty state message" do
        get lecture_home_path(lecture)

        expect(response.body.squish).to include(
          I18n.t("registration.user_registration.index.confirmed_cases")
        )
        expect(response.body.squish).to include("Tutorial 2")
        expect(response.body).not_to include("student-registration-rosterized-notice--neutral")
        expect(response.body.squish).not_to include(
          I18n.t("registration.user_registration.index.unassigned_notice")
        )
        expect(response.body.squish).not_to include(
          I18n.t("roster.self_enrollment.no_registration_options")
        )
      end
    end

    context "when the user is the lecture's teacher" do
      let(:lecture) { create(:lecture, teacher: user) }
      let!(:campaign) do
        create(:registration_campaign, :open, :first_come_first_served,
               campaignable: lecture)
      end

      it "renders the home page without student registration workflow" do
        get lecture_home_path(lecture)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('id="student_registration_options"')
        expect(response.body.squish).not_to include(
          I18n.t("registration.user_registration.index.unassigned_notice")
        )
        expect(response.body).not_to include(I18n.t("registration.user_registration.register_now"))
      end
    end

    context "when the lecture is not published" do
      let(:lecture) { create(:lecture) }

      it "redirects to root" do
        get lecture_home_path(lecture)

        expect(response).to redirect_to(root_path)
      end
    end
  end

  context "first-come-first-served tutorial campaign" do
    let(:campaign) do
      create(:registration_campaign, :open, :first_come_first_served,
             campaignable: lecture)
    end
    let(:item) { campaign.registration_items.first }
    describe "POST campaign_registrations/:campaign_id/items/:item_id/register" do
      it "creates a registration and redirects" do
        service_double = instance_double(UserRegistrations::LectureFirstComeFirstServedEditService)
        expect(UserRegistrations::LectureFirstComeFirstServedEditService).to receive(:new)
          .with(campaign, an_instance_of(User))
          .and_return(service_double)
        expect(service_double).to receive(:register!).and_return(stub_success)
        post register_item_path(campaign_id: campaign.id, item_id: item.id)

        expect(response).to have_http_status(:found)
        follow_redirect!
        expect(response.body).to include(I18n.t("registration.user_registration.messages." \
                                                "registration_success"))
      end

      context "when the user is not allowed to enroll" do
        let(:lecture) { create(:lecture, teacher: user) }
        let(:campaign) do
          create(:registration_campaign, :open, :first_come_first_served,
                 campaignable: lecture)
        end

        it "rejects the request before invoking the service" do
          expect(UserRegistrations::LectureFirstComeFirstServedEditService).not_to receive(:new)

          post register_item_path(campaign_id: campaign.id, item_id: item.id)

          expect(response).to redirect_to(root_path)
        end
      end
    end

    describe "DELETE campaign_registrations/:campaign_id/items/:item_id/withdraw" do
      before do
        Registration::UserRegistration.create!(
          registration_campaign: campaign,
          registration_item: item,
          user: user,
          status: :confirmed
        )
      end

      it "withdraws the registration" do
        service_double = instance_double(UserRegistrations::LectureFirstComeFirstServedEditService)
        expect(UserRegistrations::LectureFirstComeFirstServedEditService).to receive(:new)
          .with(campaign, user)
          .and_return(service_double)
        expect(service_double).to receive(:withdraw!).and_return(stub_success)
        delete withdraw_item_path(campaign_id: campaign.id, item_id: item.id)

        expect(response).to have_http_status(:found)
      end

      context "when the user is not allowed to enroll" do
        let(:lecture) { create(:lecture, teacher: user) }
        let(:campaign) do
          create(:registration_campaign, :open, :first_come_first_served,
                 campaignable: lecture)
        end

        it "rejects the request before invoking the service" do
          expect(UserRegistrations::LectureFirstComeFirstServedEditService).not_to receive(:new)

          delete withdraw_item_path(campaign_id: campaign.id, item_id: item.id)

          expect(response).to redirect_to(root_path)
        end
      end

      context "when the route campaign does not match the item's campaign" do
        let(:campaign) do
          create(:registration_campaign, :closed, :first_come_first_served,
                 campaignable: lecture)
        end
        let(:open_campaign) do
          create(:registration_campaign, :open, :first_come_first_served)
        end

        it "uses the item's campaign for withdrawal validation" do
          expect do
            delete(withdraw_item_path(campaign_id: open_campaign.id, item_id: item.id))
          end.not_to change(Registration::UserRegistration, :count)

          expect(response).to redirect_to(lecture_home_path(campaign.campaignable))
          expect(flash[:alert]).to eq(
            I18n.t("registration.user_registration.messages.campaign_not_opened")
          )
        end
      end
    end
  end

  context "preference based tutorial campaign" do
    let(:campaign) do
      FactoryBot.create(
        :registration_campaign,
        :open,
        :preference_based,
        campaignable: lecture
      )
    end
    let(:item) { campaign.registration_items.first }
    let(:item2) { campaign.registration_items.second }
    let(:item3) { campaign.registration_items.third }
    let(:preferences) do
      {
        "1" => item.id,
        "2" => item2.id,
        "3" => item3.id
      }
    end

    describe "preference actions" do
      let(:service_double) { instance_double(UserRegistrations::PreferencesHandler) }

      describe "POST #save_preferences" do
        it "saves all selected preference ranks" do
          pref_items = [
            UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item.id, 1),
            UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item2.id, 2),
            UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item3.id, 3)
          ]
          edit_service = instance_double(
            UserRegistrations::LecturePreferenceEditService
          )

          expect(UserRegistrations::PreferencesHandler).to receive(:new)
            .and_return(service_double)
          expect(service_double).to receive(:pref_items_from_ranked_params)
            .with(preferences)
            .and_return(pref_items)
          expect(UserRegistrations::LecturePreferenceEditService).to receive(:new)
            .with(campaign, user)
            .and_return(edit_service)
          expect(edit_service).to receive(:update!).with(pref_items).and_return(stub_success)

          post save_preferences_path(campaign), params: { preferences: preferences }
          expect(response).to have_http_status(:found)
        end

        it "only permits preference rank keys" do
          edit_service = instance_double(
            UserRegistrations::LecturePreferenceEditService,
            update!: stub_success
          )

          expect(UserRegistrations::PreferencesHandler).to receive(:new)
            .and_return(service_double)
          expect(service_double).to receive(:pref_items_from_ranked_params)
            .with(preferences)
            .and_return([])
          expect(UserRegistrations::LecturePreferenceEditService).to receive(:new)
            .with(campaign, user)
            .and_return(edit_service)

          post save_preferences_path(campaign),
               params: { preferences: preferences.merge("4" => item.id, "admin" => "1") }

          expect(response).to have_http_status(:found)
        end

        it "returns bad request for scalar preferences payloads" do
          expect(UserRegistrations::PreferencesHandler).not_to receive(:new)
          expect(UserRegistrations::LecturePreferenceEditService).not_to receive(:new)

          post save_preferences_path(campaign), params: { preferences: "foo" }

          expect(response).to have_http_status(:bad_request)
        end

        it "updates the rosterized notice box via turbo stream" do
          post save_preferences_path(campaign),
               params: { preferences: preferences },
               as: :turbo_stream

          expect(response).to have_http_status(:success)
          expect(response.media_type).to eq(Mime[:turbo_stream])
          expect(response.body).to include('target="student_registration_rosterized_entries"')
          expect(response.body).to include(
            I18n.t("registration.user_registration.index.pending_preference_notice")
          )
        end

        context "when the user is not allowed to enroll" do
          let(:lecture) { create(:lecture, teacher: user) }
          let(:campaign) do
            create(:registration_campaign, :open, :preference_based,
                   campaignable: lecture)
          end

          it "rejects the request before invoking the service" do
            expect(UserRegistrations::PreferencesHandler).not_to receive(:new)
            expect(UserRegistrations::LecturePreferenceEditService).not_to receive(:new)

            post save_preferences_path(campaign), params: { preferences: preferences }

            expect(response).to redirect_to(root_path)
          end
        end
      end
    end
  end

  context "first-come-first-served talk campaign" do
    let(:campaign) do
      create(:registration_campaign, :open, :first_come_first_served, campaignable: seminar)
    end
    let(:item) { campaign.registration_items.first }
    describe "POST campaign_registrations/:campaign_id/items/:item_id/register" do
      it "creates a registration and redirects" do
        service_double = instance_double(UserRegistrations::LectureFirstComeFirstServedEditService)
        expect(UserRegistrations::LectureFirstComeFirstServedEditService).to receive(:new)
          .with(campaign, an_instance_of(User))
          .and_return(service_double)
        expect(service_double).to receive(:register!).and_return(stub_success)
        post register_item_path(campaign_id: campaign.id, item_id: item.id)

        expect(response).to have_http_status(:found)
        follow_redirect!
        expect(response.body).to include(I18n.t("registration.user_registration.messages." \
                                                "registration_success"))
      end
    end

    describe "DELETE campaign_registrations/:campaign_id/items/:item_id/withdraw" do
      before do
        Registration::UserRegistration.create!(
          registration_campaign: campaign,
          registration_item: item,
          user: user,
          status: :confirmed
        )
      end

      it "withdraws the registration" do
        service_double = instance_double(UserRegistrations::LectureFirstComeFirstServedEditService)
        expect(UserRegistrations::LectureFirstComeFirstServedEditService).to receive(:new)
          .with(campaign, user)
          .and_return(service_double)
        expect(service_double).to receive(:withdraw!).and_return(stub_success)
        delete withdraw_item_path(campaign_id: campaign.id, item_id: item.id)

        expect(response).to have_http_status(:found)
      end
    end
  end

  context "preference based tutorial campaign" do
    let(:campaign) do
      FactoryBot.create(
        :registration_campaign,
        :open,
        :preference_based,
        campaignable: seminar
      )
    end
    let(:item) { campaign.registration_items.first }
    let(:item2) { campaign.registration_items.second }
    let(:item3) { campaign.registration_items.third }
    let(:preferences) do
      {
        "1" => item.id,
        "2" => item2.id,
        "3" => item3.id
      }
    end

    describe "preference actions" do
      let(:service_double) { instance_double(UserRegistrations::PreferencesHandler) }

      describe "POST #save_preferences" do
        it "saves all selected preference ranks" do
          pref_items = [
            UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item.id, 1),
            UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item2.id, 2),
            UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item3.id, 3)
          ]
          edit_service = instance_double(
            UserRegistrations::LecturePreferenceEditService
          )

          expect(UserRegistrations::PreferencesHandler).to receive(:new)
            .and_return(service_double)
          expect(service_double).to receive(:pref_items_from_ranked_params)
            .with(preferences)
            .and_return(pref_items)
          expect(UserRegistrations::LecturePreferenceEditService).to receive(:new)
            .with(campaign, user)
            .and_return(edit_service)
          expect(edit_service).to receive(:update!).with(pref_items).and_return(stub_success)

          post save_preferences_path(campaign), params: { preferences: preferences }
          expect(response).to have_http_status(:found)
        end
      end
    end
  end
end
