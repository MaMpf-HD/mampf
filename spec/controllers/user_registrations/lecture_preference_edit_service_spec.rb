require "rails_helper"

RSpec.describe(UserRegistrations::LecturePreferenceEditService, type: :service) do
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
    let(:item3) { campaign.registration_items.third }
    let(:pref_from_fe) do
      UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item2.id, 1)
    end
    let(:pref_from_fe2) do
      UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item.id, 2)
    end
    let(:pref_from_fe3) do
      UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item3.id, 3)
    end
    let(:pref_items) { [pref_from_fe, pref_from_fe2, pref_from_fe3] }

    it "creates a pending registration when validations pass" do
      service = described_class.new(campaign, user)
      expect do
        service.update!(pref_items)
      end.to change { Registration::UserRegistration.count }.by(3)

      registrations = Registration::UserRegistration.last(3)
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
        end.to change { Registration::UserRegistration.count }.by(2)

        registrations = Registration::UserRegistration.last(3)
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
      expect(result.errors).to include(
        I18n.t("registration.user_registration.messages.campaign_not_opened")
      )
    end

    it "rejects incomplete preference ranks" do
      service = described_class.new(campaign, user)
      result = service.update!([pref_from_fe, pref_from_fe2])

      expect(result.success?).to be(false)
      expect(result.errors).to include(
        I18n.t("registration.user_registration.messages.invalid_preferences")
      )
    end

    it "rejects duplicate preference items" do
      duplicate_items = [
        pref_from_fe,
        UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item2.id, 2),
        pref_from_fe3
      ]
      service = described_class.new(campaign, user)
      result = service.update!(duplicate_items)

      expect(result.success?).to be(false)
      expect(result.errors).to include(
        I18n.t("registration.user_registration.messages.invalid_preferences")
      )
    end

    it "rejects preferences when the user cannot leave their current tutorial" do
      add_only_tutorial = create(:tutorial,
                                 lecture: campaign.campaignable,
                                 skip_campaigns: true,
                                 self_materialization_mode: :add_only)
      add_only_tutorial.add_user_to_roster!(user)
      service = described_class.new(campaign, user)

      result = service.update!(pref_items)

      expect(result.success?).to be(false)
      expect(result.errors).to include(
        I18n.t("registration.user_registration.messages.unremovable_assignment")
      )
    end

    it "rejects more ranks than available options" do
      extra = UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item3.id, 4)
      service = described_class.new(campaign, user)
      result = service.update!(pref_items + [extra])

      expect(result.success?).to be(false)
      expect(result.errors).to include(
        I18n.t("registration.user_registration.messages.invalid_preferences")
      )
    end

    it "rejects preference items from another campaign" do
      other_campaign = create(:registration_campaign, :preference_based, :open)
      foreign_item = other_campaign.registration_items.first
      foreign_pref_items = [
        UserRegistrations::PreferencesHandler::SimpleItemPreference.new(foreign_item.id, 1),
        pref_from_fe2,
        pref_from_fe3
      ]
      service = described_class.new(campaign, user)

      result = service.update!(foreign_pref_items)

      expect(result.success?).to be(false)
      expect(result.errors).to include(
        I18n.t("registration.user_registration.messages.invalid_options")
      )
    end
  end

  describe "campaign with only two options" do
    let(:campaign) do
      FactoryBot.create(:registration_campaign, :preference_based, :draft)
    end
    let!(:item) do
      FactoryBot.create(:registration_item, registration_campaign: campaign)
    end
    let!(:item2) do
      FactoryBot.create(:registration_item, registration_campaign: campaign)
    end

    before { campaign.update!(status: :open) }

    it "accepts exactly two ranks" do
      pref_items = [
        UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item.id, 1),
        UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item2.id, 2)
      ]
      service = described_class.new(campaign, user)

      expect { service.update!(pref_items) }
        .to change { Registration::UserRegistration.count }.by(2)
    end

    it "rejects a third rank that has no matching option" do
      pref_items = [
        UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item.id, 1),
        UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item2.id, 2),
        UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item.id, 3)
      ]
      service = described_class.new(campaign, user)
      result = service.update!(pref_items)

      expect(result.success?).to be(false)
      expect(result.errors).to include(
        I18n.t("registration.user_registration.messages.invalid_preferences")
      )
    end
  end

  describe "edit preference in mixed campaign (cohort + tutorial)" do
    let(:lecture) { FactoryBot.create(:lecture, teacher: teacher) }
    let(:campaign) { FactoryBot.create(:registration_campaign, :preference_based, :draft) }
    let(:tutorial) { FactoryBot.create(:tutorial, lecture: lecture, capacity: 20) }
    let(:cohort) do
      FactoryBot.create(:cohort,
                        context: lecture,
                        propagate_to_lecture: true,
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
    let(:pref_from_fe) do
      UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item2.id, 1)
    end
    let(:pref_from_fe2) do
      UserRegistrations::PreferencesHandler::SimpleItemPreference.new(item.id, 2)
    end
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
