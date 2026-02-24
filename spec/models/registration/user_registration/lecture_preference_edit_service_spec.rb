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
      expect(result.errors).to include(
        I18n.t("registration.user_registration.messages.campaign_not_opened")
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

  describe "preference-based campaign with 1 exam" do
    let(:lecture) { FactoryBot.create(:lecture, teacher: teacher) }
    let(:exam) { FactoryBot.create(:exam, :with_date, lecture: lecture) }

    let(:campaign) do
      FactoryBot.create(:registration_campaign,
                        :preference_based,
                        :open,
                        campaignable: lecture)
    end

    let!(:item_exam) do
      FactoryBot.create(:registration_item,
                        registration_campaign: campaign,
                        registerable: exam)
    end

    let(:pref) do
      [
        Registration::UserRegistration::PreferencesHandler::SimpleItemPreference.new(item_exam.id,
                                                                                     1)
      ]
    end

    it "creates a pending registration" do
      service = described_class.new(campaign, user)

      expect do
        service.update!(pref)
      end.to change { Registration::UserRegistration.count }.by(1)

      registration = Registration::UserRegistration.last
      expect(registration.registration_item).to eq(item_exam)
      expect(registration.status).to eq("pending")
      expect(registration.preference_rank).to eq(1)
    end
  end

  describe "preference-based campaign with 2 exams" do
    let(:lecture) { FactoryBot.create(:lecture, teacher: teacher) }
    let(:exam1) { FactoryBot.create(:exam, :with_date, lecture: lecture) }
    let(:exam2) { FactoryBot.create(:exam, :with_date, lecture: lecture) }

    let(:campaign) do
      FactoryBot.create(:registration_campaign,
                        :preference_based,
                        :open,
                        campaignable: lecture)
    end

    let!(:item_exam1) do
      FactoryBot.create(:registration_item,
                        registration_campaign: campaign,
                        registerable: exam1)
    end

    let!(:item_exam2) do
      FactoryBot.create(:registration_item,
                        registration_campaign: campaign,
                        registerable: exam2)
    end

    let(:prefs) do
      [
        Registration::UserRegistration::PreferencesHandler::SimpleItemPreference.new(item_exam1.id,
                                                                                     1),
        Registration::UserRegistration::PreferencesHandler::SimpleItemPreference.new(item_exam2.id,
                                                                                     2)
      ]
    end

    it "creates pending registrations for both exams" do
      service = described_class.new(campaign, user)

      expect do
        service.update!(prefs)
      end.to change { Registration::UserRegistration.count }.by(2)

      reg1 = Registration::UserRegistration.find_by(registration_item: item_exam1)
      reg2 = Registration::UserRegistration.find_by(registration_item: item_exam2)

      expect(reg1.preference_rank).to eq(1)
      expect(reg2.preference_rank).to eq(2)
    end

    it "updates existing registration ranks" do
      Registration::UserRegistration.create!(
        registration_campaign: campaign,
        registration_item: item_exam2,
        user: user,
        status: :pending,
        preference_rank: 5
      )

      service = described_class.new(campaign, user)

      expect do
        service.update!(prefs)
      end.to change { Registration::UserRegistration.count }.by(1)

      reg1 = Registration::UserRegistration.find_by(registration_item: item_exam1)
      reg2 = Registration::UserRegistration.find_by(registration_item: item_exam2)

      expect(reg1.preference_rank).to eq(1)
      expect(reg2.preference_rank).to eq(2)
    end
  end

  describe "preference-based campaign with predecessor tutorial and successor exam" do
    let(:lecture) { FactoryBot.create(:lecture, teacher: teacher) }
    let(:tutorial) do
      FactoryBot.create(:tutorial,
                        lecture: lecture,
                        capacity: 20)
    end

    let(:exam) do
      FactoryBot.create(:exam, :with_date, lecture: lecture)
    end
    let(:campaign1) do
      FactoryBot.create(:registration_campaign,
                        :preference_based,
                        :open,
                        campaignable: lecture)
    end
    let!(:item_tutorial) do
      FactoryBot.create(:registration_item,
                        registration_campaign: campaign1,
                        registerable: tutorial)
    end
    let(:campaign2) do
      FactoryBot.create(:registration_campaign,
                        :preference_based,
                        :open,
                        :with_prerequisite_policy,
                        campaignable: lecture,
                        parent_campaign: campaign1)
    end
    let!(:item_exam) do
      FactoryBot.create(:registration_item,
                        registration_campaign: campaign2,
                        registerable: exam)
    end
    let(:policy) { campaign2.registration_policies.find_by(kind: :prerequisite_campaign) }

    before do
      Registration::UserRegistration.delete_all
    end

    it "has correct prerequisite campaign id" do
      expect(policy.config["prerequisite_campaign_id"]).to eq(campaign1.id)
    end

    it "fails to update preferences when predecessor tutorial is not registered" do
      pref = [
        Registration::UserRegistration::PreferencesHandler::SimpleItemPreference.new(item_exam.id,
                                                                                     1)
      ]

      service = described_class.new(campaign2, user)
      result = service.update!(pref)

      expect(result.success?).to be(false)
      expect(result.errors).to include(
        I18n.t("registration.user_registration.messages.requirements_not_met")
      )
    end

    it "succeeds to update preferences when predecessor tutorial is registered" do
      # Register in campaign1
      pref1 = [
        Registration::UserRegistration::PreferencesHandler::SimpleItemPreference.new(
          item_tutorial.id, 1
        )
      ]
      service1 = described_class.new(campaign1, user)
      service1.update!(pref1)

      # preferences in campaign2
      pref2 = [
        Registration::UserRegistration::PreferencesHandler::SimpleItemPreference.new(item_exam.id,
                                                                                     1)
      ]
      service2 = described_class.new(campaign2, user)
      result = service2.update!(pref2)

      expect(result.success?).to be(true)
      registration = Registration::UserRegistration.last
      expect(registration.registration_item).to eq(item_exam)
      expect(registration.status).to eq("pending")
      expect(registration.preference_rank).to eq(1)
    end
  end
end
