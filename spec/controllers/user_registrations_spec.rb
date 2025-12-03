require "rails_helper"

RSpec.describe(Registration::UserRegistrationsController, type: :controller) do
  let(:user) { create(:confirmed_user) }
  let(:lecture) { FactoryBot.create(:lecture) }

  let(:item) { campaign.registration_items.first }

  before { sign_in user }

  context "lecture FCFS campaign" do
    let(:campaign) do
      FactoryBot.create(
        :registration_campaign,
        :open,
        :for_lecture_enrollment,
        :first_come_first_served
      )
    end
    let(:item) { campaign.registration_items.first }
    describe "calls LectureFcfsEditService for lecture FCFS campaign" do
      it "POST create" do
        service_double = instance_double(Registration::LectureFcfsEditService)
        expect(Registration::LectureFcfsEditService).to receive(:new)
          .with(campaign, item, an_instance_of(User))
          .and_return(service_double)
        expect(service_double).to receive(:register!)

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
        service_double = instance_double(Registration::LectureFcfsEditService)
        expect(Registration::LectureFcfsEditService).to receive(:new)
          .with(campaign, item, user)
          .and_return(service_double)
        expect(service_double).to receive(:withdraw!)

        delete :destroy, params: { campaign_id: campaign.id, item_id: item.id }
      end
    end
  end

  context "tutorial FCFS campaign" do
    let(:campaign) do
      FactoryBot.create(
        :registration_campaign,
        :open,
        :for_tutorial_enrollment,
        :first_come_first_served
      )
    end
    let(:item) { campaign.registration_items.first }
    describe "calls LectureFcfsEditService for lecture FCFS campaign" do
      it "POST create" do
        service_double = instance_double(Registration::LectureFcfsEditService)
        expect(Registration::LectureFcfsEditService).to receive(:new)
          .with(campaign, item, an_instance_of(User))
          .and_return(service_double)
        expect(service_double).to receive(:register!)

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
        service_double = instance_double(Registration::LectureFcfsEditService)
        expect(Registration::LectureFcfsEditService).to receive(:new)
          .with(campaign, item, user)
          .and_return(service_double)
        expect(service_double).to receive(:withdraw!)

        delete :destroy, params: { campaign_id: campaign.id, item_id: item.id }
      end
    end
  end

  context "talk FCFS campaign" do
    let(:campaign) do
      FactoryBot.create(
        :registration_campaign,
        :open,
        :for_talk_enrollment,
        :first_come_first_served
      )
    end
    let(:item) { campaign.registration_items.first }
    describe "calls LectureFcfsEditService for lecture FCFS campaign" do
      it "POST create" do
        service_double = instance_double(Registration::LectureFcfsEditService)
        expect(Registration::LectureFcfsEditService).to receive(:new)
          .with(campaign, item, an_instance_of(User))
          .and_return(service_double)
        expect(service_double).to receive(:register!)

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
        service_double = instance_double(Registration::LectureFcfsEditService)
        expect(Registration::LectureFcfsEditService).to receive(:new)
          .with(campaign, item, user)
          .and_return(service_double)
        expect(service_double).to receive(:withdraw!)

        delete :destroy, params: { campaign_id: campaign.id, item_id: item.id }
      end
    end
  end
end
