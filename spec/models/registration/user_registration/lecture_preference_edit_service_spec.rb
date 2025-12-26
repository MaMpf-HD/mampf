require "rails_helper"

RSpec.describe(Registration::UserRegistration::LecturePreferenceEditService, type: :service) do
  let(:user) { FactoryBot.create(:user, email: "student@mampf.edu") }
  let(:lecture) { FactoryBot.create(:lecture, teacher: teacher) }

  describe "edit preference tutorial campaign" do
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
      service = described_class.new(campaign, user)

      expect do
        service.update!(pref_items)
      end.to change { Registration::UserRegistration.count }.by(2)

      registration = Registration::UserRegistration.last
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

      registration = Registration::UserRegistration.second_to_last
      expect(registration.registration_item).to eq(item2)
      expect(registration.preference_rank).to eq(1)

      registration2 = Registration::UserRegistration.last
      expect(registration2.registration_item).to eq(item)
      expect(registration2.preference_rank).to eq(2)
    end

    it "raises error if campaign is closed" do
      campaign.update!(status: :closed)
      service = described_class.new(campaign, user)
      result = service.update!(pref_items)
      expect(result.success?).to be(false)
      expect(result.errors).to include(I18n.t("registration.messages.campaign_not_opened"))
    end
  end
end
