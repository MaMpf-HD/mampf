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

    it "destroys the registration" do
      expect do
        delete(path, headers: { "Accept" => "text/vnd.turbo-stream.html" })
      end.to change(Registration::UserRegistration, :count).by(-1)
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
  let(:lecture) { create(:lecture) }
  let(:seminar) { create(:lecture, :is_seminar) }
  let(:stub_success) { Registration::UserRegistration::Handler::Result.new(true, []) }
  let(:stub_succeed_items) { [item] }

  before do
    Flipper.enable(:registration_campaigns)
    sign_in user
  end

  describe "GET lectures/:lecture_id/campaign_registrations" do
    context "open + fcfs tutorial campaign" do
      let(:campaign) do
        FactoryBot.create(:registration_campaign,
                          :first_come_first_served,
                          :open,
                          :with_policies,
                          campaignable: lecture,
                          description: "Solver Test Campaign")
      end
      it "return success response" do
        get lecture_campaign_registrations_path(lecture_id: lecture.id)
        expect(campaign.campaignable_type).to eq("Lecture")
        expect(response).to have_http_status(:ok)
      end
    end

    context "completed campaign" do
      let(:campaign) do
        FactoryBot.create(:registration_campaign, :first_come_first_served,
                          :completed_after_policies,
                          campaignable: seminar,
                          description: "Solver Test Campaign")
      end
      it "return success response" do
        get lecture_campaign_registrations_path(lecture_id: seminar.id)
        expect(campaign.campaignable_type).to eq("Lecture")
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "fcfs tutorial campaign" do
    let(:campaign) { create(:registration_campaign, :open, :first_come_first_served) }
    let(:item) { campaign.registration_items.first }
    describe "POST campaign_registrations/:campaign_id/items/:item_id/register" do
      it "creates a registration and redirects" do
        service_double = instance_double(Registration::UserRegistration::LectureFcfsEditService)
        expect(Registration::UserRegistration::LectureFcfsEditService).to receive(:new)
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
        service_double = instance_double(Registration::UserRegistration::LectureFcfsEditService)
        expect(Registration::UserRegistration::LectureFcfsEditService).to receive(:new)
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
        :preference_based
      )
    end
    let(:item) { campaign.registration_items.first }
    let(:item2) { campaign.registration_items.second }
    let(:item3) { campaign.registration_items.third }
    let(:pref_from_fe) { Registration::UserRegistration::PreferencesHandler::ItemPreference.new(item2, 1) }
    let(:pref_from_fe2) { Registration::UserRegistration::PreferencesHandler::ItemPreference.new(item, 2) }
    let(:pref_from_fe3) { Registration::UserRegistration::PreferencesHandler::ItemPreference.new(item3, 3) }
    let(:pref_items_json) do
      [{ item: item2, rank: 1 }, { item: item, rank: 2 }, { item: item3, rank: 3 }].to_json
    end
    describe "POST user_registrations/:campaign_id/save" do
      it "updates preferences campaign" do
        service_double = instance_double(Registration::UserRegistration::LecturePreferenceEditService)
        expect(Registration::UserRegistration::LecturePreferenceEditService).to receive(:new)
          .with(campaign, an_instance_of(User))
          .and_return(service_double)
        expect(service_double).to receive(:update!).and_return(stub_success)
        post save_campaign_preferences_path(campaign_id: campaign.id),
             params: { preferences_json: pref_items_json }

        expect(response).to have_http_status(:found)
        follow_redirect!
        expect(response.body).to include(I18n.t("registration.user_registration.messages." \
                                                "registration_success"))
      end
    end

    describe "preference actions" do
      let(:service_double) { instance_double(Registration::UserRegistration::PreferencesHandler) }

      [:up, :down].each do |action|
        describe "POST ##{action}" do
          it "updates preferences via #{action}" do
            expect(Registration::UserRegistration::PreferencesHandler).to receive(:new)
              .and_return(service_double)
            expect(service_double).to receive(action).and_return(stub_success)
            post send("preference_#{action}_path", item),
                 params: { preferences_json: pref_items_json }
          end
        end
      end

      [:add, :remove].each do |action|
        describe "POST ##{action}" do
          it "updates preferences via #{action}" do
            expect(Registration::UserRegistration::PreferencesHandler).to receive(:new)
              .and_return(service_double)
            expect(service_double).to receive(action).and_return(stub_success)
            post send("#{action}_preference_path", item),
                 params: { preferences_json: pref_items_json }
          end
        end
      end
    end
  end

  context "fcfs talk campaign" do
    let(:campaign) do
      create(:registration_campaign, :open, :first_come_first_served, campaignable: seminar)
    end
    let(:item) { campaign.registration_items.first }
    describe "POST campaign_registrations/:campaign_id/items/:item_id/register" do
      it "creates a registration and redirects" do
        service_double = instance_double(Registration::UserRegistration::LectureFcfsEditService)
        expect(Registration::UserRegistration::LectureFcfsEditService).to receive(:new)
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
        service_double = instance_double(Registration::UserRegistration::LectureFcfsEditService)
        expect(Registration::UserRegistration::LectureFcfsEditService).to receive(:new)
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
    let(:pref_from_fe) { Registration::UserRegistration::PreferencesHandler::ItemPreference.new(item2, 1) }
    let(:pref_from_fe2) { Registration::UserRegistration::PreferencesHandler::ItemPreference.new(item, 2) }
    let(:pref_from_fe3) { Registration::UserRegistration::PreferencesHandler::ItemPreference.new(item3, 3) }
    let(:pref_items_json) do
      [{ item: item2, rank: 1 }, { item: item, rank: 2 }, { item: item3, rank: 3 }].to_json
    end
    describe "POST user_registrations/:campaign_id/save" do
      it "updates preferences campaign" do
        service_double = instance_double(Registration::UserRegistration::LecturePreferenceEditService)
        expect(Registration::UserRegistration::LecturePreferenceEditService).to receive(:new)
          .with(campaign, an_instance_of(User))
          .and_return(service_double)
        expect(service_double).to receive(:update!).and_return(stub_success)
        post save_campaign_preferences_path(campaign_id: campaign.id),
             params: { preferences_json: pref_items_json }

        expect(response).to have_http_status(:found)
        follow_redirect!
        expect(response.body).to include(I18n.t("registration.user_registration.messages." \
                                                "registration_success"))
      end
    end

    describe "preference actions" do
      let(:service_double) { instance_double(Registration::UserRegistration::PreferencesHandler) }

      [:up, :down].each do |action|
        describe "POST ##{action}" do
          it "updates preferences via #{action}" do
            expect(Registration::UserRegistration::PreferencesHandler).to receive(:new)
              .and_return(service_double)
            expect(service_double).to receive(action).and_return(stub_success)
            post send("preference_#{action}_path", item),
                 params: { preferences_json: pref_items_json }
          end
        end
      end

      [:add, :remove].each do |action|
        describe "POST ##{action}" do
          it "updates preferences via #{action}" do
            expect(Registration::UserRegistration::PreferencesHandler).to receive(:new)
              .and_return(service_double)
            expect(service_double).to receive(action).and_return(stub_success)
            post send("#{action}_preference_path", item),
                 params: { preferences_json: pref_items_json }
          end
        end
      end
    end
  end
end
