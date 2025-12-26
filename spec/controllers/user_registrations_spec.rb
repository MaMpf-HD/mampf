require "rails_helper"

RSpec.describe(Registration::UserRegistrationsController, type: :controller) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { create(:lecture) }
  let(:seminar) { create(:lecture, :is_seminar) }

  let(:item) { campaign.registration_items.first }

  let(:stub_success) { Registration::UserRegistration::Handler::Result.new(true, []) }

  before { sign_in user }

  context "lecture FCFS campaign open" do
    let(:campaign) do
      FactoryBot.create(
        :registration_campaign,
        :open,
        :first_come_first_served, self_registerable: true
      )
    end
    let(:item) { campaign.registration_items.first }
    describe "calls LectureFcfsEditService for lecture FCFS campaign" do
      it "POST create" do
        service_double = instance_double(Registration::UserRegistration::LectureFcfsEditService)
        expect(Registration::UserRegistration::LectureFcfsEditService).to receive(:new)
          .with(campaign, an_instance_of(User), item)
          .and_return(service_double)
        expect(service_double).to receive(:register!).and_return(stub_success)

        post :create, params: { campaign_id: campaign.id, item_id: item.id }
      end
    end
    describe "DELETE #destroy" do
      before do
        Registration::UserRegistration.create!(
          registration_campaign: campaign,
          registration_item: item,
          user: user,
          status: :confirmed
        )
      end

      it "calls LectureFcfsEditService.withdraw! for lecture FCFS campaign" do
        service_double = instance_double(Registration::UserRegistration::LectureFcfsEditService)
        expect(Registration::UserRegistration::LectureFcfsEditService).to receive(:new)
          .with(campaign, user, item)
          .and_return(service_double)
        expect(service_double).to receive(:withdraw!).and_return(stub_success)

        delete :destroy, params: { campaign_id: campaign.id, item_id: item.id }
      end
    end
  end

  context "tutorial FCFS campaign open" do
    let(:campaign) do
      FactoryBot.create(
        :registration_campaign,
        :open,
        :first_come_first_served
      )
    end
    let(:item) { campaign.registration_items.first }
    describe "calls LectureFcfsEditService for lecture FCFS campaign" do
      it "POST create" do
        service_double = instance_double(Registration::UserRegistration::LectureFcfsEditService)
        expect(Registration::UserRegistration::LectureFcfsEditService).to receive(:new)
          .with(campaign, an_instance_of(User), item)
          .and_return(service_double)
        expect(service_double).to receive(:register!).and_return(stub_success)

        post :create, params: { campaign_id: campaign.id, item_id: item.id }
      end
    end
    describe "DELETE #destroy" do
      before do
        Registration::UserRegistration.create!(
          registration_campaign: campaign,
          registration_item: item,
          user: user,
          status: :confirmed
        )
      end

      it "calls LectureFcfsEditService.withdraw! for lecture FCFS campaign" do
        service_double = instance_double(Registration::UserRegistration::LectureFcfsEditService)
        expect(Registration::UserRegistration::LectureFcfsEditService).to receive(:new)
          .with(campaign, user, item)
          .and_return(service_double)
        expect(service_double).to receive(:withdraw!).and_return(stub_success)

        delete :destroy, params: { campaign_id: campaign.id, item_id: item.id }
      end
    end
  end

  context "tutorial PB campaign open" do
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
    let(:pref_items_json) { [pref_from_fe, pref_from_fe2, pref_from_fe3].to_json }
    describe "calls LecturePreferenceEditService for update action" do
      it "POST update" do
        service_double = instance_double(Registration::UserRegistration::LecturePreferenceEditService)
        expect(Registration::UserRegistration::LecturePreferenceEditService).to receive(:new)
          .with(campaign, an_instance_of(User))
          .and_return(service_double)
        expect(service_double).to receive(:update!).and_return(stub_success)

        post :update, params: { campaign_id: campaign.id, preferences_json: pref_items_json }
      end
    end

    describe "should delegate preferences action to correct service" do
      let(:service_double) { instance_double(Registration::UserRegistration::PreferencesHandler) }
      [:up, :down, :add, :remove].each do |action|
        it "POST #{action}" do
          expect(Registration::UserRegistration::PreferencesHandler).to receive(:new)
            .and_return(service_double)
          expect(service_double).to receive(action).and_return(stub_success)

          post action, params: { item_id: item.id, preferences_json: pref_items_json }
        end
      end
    end
  end

  context "talk FCFS campaign open" do
    let(:campaign) do
      FactoryBot.create(
        :registration_campaign,
        :open,
        :first_come_first_served,
        campaignable: seminar
      )
    end
    let(:item) { campaign.registration_items.first }
    describe "calls LectureFcfsEditService for lecture FCFS campaign" do
      it "POST create" do
        service_double = instance_double(Registration::UserRegistration::LectureFcfsEditService)
        expect(Registration::UserRegistration::LectureFcfsEditService).to receive(:new)
          .with(campaign, an_instance_of(User), item)
          .and_return(service_double)
        expect(service_double).to receive(:register!).and_return(stub_success)

        post :create, params: { campaign_id: campaign.id, item_id: item.id }
      end
    end
    describe "DELETE #destroy" do
      before do
        Registration::UserRegistration.create!(
          registration_campaign: campaign,
          registration_item: item,
          user: user,
          status: :confirmed
        )
      end

      it "calls LectureFcfsEditService.withdraw! for lecture FCFS campaign" do
        service_double = instance_double(Registration::UserRegistration::LectureFcfsEditService)
        expect(Registration::UserRegistration::LectureFcfsEditService).to receive(:new)
          .with(campaign, user, item)
          .and_return(service_double)
        expect(service_double).to receive(:withdraw!).and_return(stub_success)

        delete :destroy, params: { campaign_id: campaign.id, item_id: item.id }
      end
    end
  end
end
