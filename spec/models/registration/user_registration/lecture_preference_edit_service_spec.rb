require "rails_helper"

RSpec.describe(Registration::UserRegistration::LecturePreferenceEditService, type: :service) do
  let(:user) { FactoryBot.create(:user, email: "student@mampf.edu") }
  let(:teacher) { FactoryBot.create(:confirmed_user) }

  describe "edit preference tutorial campaign" do
    let(:lecture) { FactoryBot.create(:lecture, teacher: teacher) }
    let(:campaign) { FactoryBot.create(:registration_campaign, :preference_based, :open) }
    let(:campaign_draft) do
      FactoryBot.create(:registration_campaign, :preference_based, :draft, :with_items)
    end
    let(:item) { campaign.registration_items.first }
    let(:item2) { campaign.registration_items.second }
    let(:pref_from_fe) { Registration::UserRegistration::PreferencesHandler::SimpleItemPreference.new(item2.id, 1) }
    let(:pref_from_fe2) { Registration::UserRegistration::PreferencesHandler::SimpleItemPreference.new(item.id, 2) }
    let(:pref_items) { [pref_from_fe, pref_from_fe2] }

    it "creates a pending registration when validations pass" do
      puts Registration::UserRegistration.count
      puts(Registration::UserRegistration.all.map do |r|
        [r.id, r.user_id, r.registration_campaign_id, r.registration_item_id, r.status]
      end)
      service = described_class.new(campaign, user)

      expect do
        service.update!(pref_items)
      end.to change { Registration::UserRegistration.count }.by(2)

      registrations = Registration::UserRegistration.last(2)
      regist_tutorial = registrations.find { |r| r.registration_item.id == item.id }
      expect(regist_tutorial.user).to eq(user)
      expect(regist_tutorial.registration_item).to eq(item)
      expect(regist_tutorial.status).to eq("pending")
      expect(regist_tutorial.preference_rank).to eq(2)
    end

    context "when there is an existing registration" do
      before do
        Registration::UserRegistration.create!(
          registration_campaign: campaign,
          registration_item: item2,
          user: user,
          status: :pending,
          preference_rank: 2
        )
      end
      it "update rank for existed registration when validations pass" do
        service = described_class.new(campaign, user)
        expect do
          service.update!(pref_items)
        end.to change { Registration::UserRegistration.count }.by(1)

        registrations = Registration::UserRegistration.last(2)
        registration2 = registrations.find { |r| r.registration_item.id == item2.id }
        registration = registrations.find { |r| r.registration_item.id == item.id }
        expect(registration2.registration_item).to eq(item2)
        expect(registration2.preference_rank).to eq(1)
        expect(registration.registration_item).to eq(item)
        expect(registration.preference_rank).to eq(2)
      end
    end

    it "raises error if campaign is closed" do
      campaign.update!(status: :closed)
      service = described_class.new(campaign, user)
      result = service.update!(pref_items)
      expect(result.success?).to be(false)
      expect(result.errors).to include(I18n.t("registration.messages.campaign_not_opened"))
    end
  end

  describe "edit preference in mixed campaign (cohort + tutorial)" do
    let(:lecture) { FactoryBot.create(:lecture, teacher: teacher) }
    let(:campaign) { FactoryBot.create(:registration_campaign, :preference_based, :draft) }
    let(:tutorial) { FactoryBot.create(:tutorial, lecture: lecture, capacity: 20) }
    let(:cohort) do
      FactoryBot.create(:cohort,
                        context: lecture,
                        purpose: :general,
                        propagate_to_lecture: false,
                        capacity: nil)
    end
    let!(:item) do
      FactoryBot.create(:registration_item,
                        registration_campaign: campaign,
                        registerable: tutorial)
    end
    let!(:item2) do
      FactoryBot.create(:registration_item,
                        registration_campaign: campaign,
                        registerable: cohort)
    end
    let(:pref_from_fe) { Registration::UserRegistration::PreferencesHandler::SimpleItemPreference.new(item2.id, 1) }
    let(:pref_from_fe2) { Registration::UserRegistration::PreferencesHandler::SimpleItemPreference.new(item.id, 2) }
    let(:pref_items) { [pref_from_fe, pref_from_fe2] }

    before do
      campaign.update!(status: :open)
    end

    it "creates a pending registration when validations pass" do
      service = described_class.new(campaign, user)

      expect do
        service.update!(pref_items)
      end.to change { Registration::UserRegistration.count }.by(2)

      registrations = Registration::UserRegistration.last(2)
      registration = registrations.find { |r| r.registration_item.id == item.id }
      expect(registration.user).to eq(user)
      expect(registration.registration_campaign).to eq(campaign)
      expect(registration.registration_item).to eq(item)
      expect(registration.status).to eq("pending")
      expect(registration.preference_rank).to eq(2)
    end

    it "update rank for existed registration when validations pass" do
      Registration::UserRegistration.create!(
        registration_campaign: campaign,
        registration_item: item2,
        user: user,
        status: :pending,
        preference_rank: 2
      )

      service = described_class.new(campaign, user)
      expect do
        service.update!(pref_items)
      end.to change { Registration::UserRegistration.count }.by(1)
      registrations = Registration::UserRegistration.last(2)
      registration = registrations.find { |r| r.registration_item.id == item.id }
      expect(registration.user).to eq(user)
      expect(registration.registration_campaign).to eq(campaign)
      expect(registration.registration_item).to eq(item)
      expect(registration.status).to eq("pending")
      expect(registration.preference_rank).to eq(2)
    end
  end
end
