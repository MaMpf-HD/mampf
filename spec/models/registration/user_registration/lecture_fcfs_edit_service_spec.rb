require "rails_helper"

RSpec.describe(Registration::UserRegistration::LectureFcfsEditService, type: :service) do
  let(:user) { FactoryBot.create(:user, email: "student@mampf.edu") }
  let(:lecture) { FactoryBot.create(:lecture) }
  let(:seminar) { FactoryBot.create(:seminar) }

  describe "planning cohort registration" do
    let(:campaign) do
      create(:registration_campaign,
             campaignable: seminar,
             status: :draft,
             allocation_mode: :first_come_first_served,
             description: "Stage 1: Planning",
             registration_deadline: 1.week.from_now)
    end
    let(:planning_cohort) do
      create(:cohort,
             context: seminar,
             purpose: :planning,
             propagate_to_lecture: false,
             capacity: nil)
    end
    let!(:item) do
      create(:registration_item, registration_campaign: campaign, registerable: planning_cohort)
    end
    it "creates a confirmed registration" do
      campaign.update!(status: :open)
      service = described_class.new(campaign, user, item)

      expect do
        service.register!
      end.to change { Registration::UserRegistration.count }.by(1)

      registration = Registration::UserRegistration.last
      expect(registration.user).to eq(user)
      expect(registration.registration_campaign).to eq(campaign)
      expect(registration.registration_item).to eq(item)
      expect(registration.status).to eq("confirmed")
    end

    it "fully deletes a registration on withdraw" do
      service = described_class.new(campaign, user, item)
      service.register!
      service.withdraw!
      registration = Registration::UserRegistration.first
      expect(registration).to be_nil
    end
  end

  describe "tutorial campaign registration" do
    let(:campaign) { FactoryBot.create(:registration_campaign, :open) }
    let(:campaign_draft) do
      create(:registration_campaign, :draft, :with_items)
    end
    let(:item) { campaign.registration_items.first }
    let(:item2) { campaign.registration_items.second }

    it "creates a confirmed registration when validations pass, case no user registration" do
      service = described_class.new(campaign, user, item)

      expect do
        service.register!
      end.to change { Registration::UserRegistration.count }.by(1)

      registration = Registration::UserRegistration.last
      expect(registration.user).to eq(user)
      expect(registration.registration_campaign).to eq(campaign)
      expect(registration.registration_item).to eq(item)
      expect(registration.status).to eq("confirmed")
    end

    context "existing rejected registration" do
      before do
        Registration::UserRegistration.create!(
          registration_campaign: campaign,
          registration_item: item2,
          user: user,
          status: :rejected
        )
      end
      it "creates a confirmed registration when validations pass" do
        service = described_class.new(campaign, user, item)
        service.register!
        registration = Registration::UserRegistration.last

        expect(registration.user).to eq(user)
        expect(registration.registration_campaign).to eq(campaign)
        expect(registration.registration_item).to eq(item)
        expect(registration.status).to eq("confirmed")
      end
    end

    context "invalid cases" do
      it "raises error if campaign is closed" do
        service = described_class.new(campaign_draft, user, item)

        result = service.register!
        expect(result.success?).to be(false)
        expect(result.errors).to include(I18n.t("registration.messages.campaign_not_opened"))
      end

      it "raises error if user already registered for another item" do
        Registration::UserRegistration.create!(
          registration_campaign: campaign,
          registration_item: item2,
          user: user,
          status: :confirmed
        )

        service = described_class.new(campaign, user, item)

        result = service.register!
        expect(result.success?).to be(false)
        expect(result.errors).to include(I18n.t("registration.messages.already_registered"))
      end

      it "raises error if item has no capacity" do
        item.registerable.update!(capacity: 0)
        service = described_class.new(campaign, user, item)

        result = service.register!
        expect(result.success?).to be(false)
        expect(result.errors).to include(I18n.t("registration.messages.no_slots"))
      end
    end
  end

  describe "withdraw tutorial campaign" do
    let(:campaign) { FactoryBot.create(:registration_campaign, :open) }
    let(:item) { campaign.registration_items.first }
    let(:item2) { campaign.registration_items.second }

    context "registered item" do
      before do
        Registration::UserRegistration.create!(
          registration_campaign: campaign,
          registration_item: item,
          user: user,
          status: :confirmed
        )
      end

      it "deletes registration" do
        service = described_class.new(campaign, user, item)
        service.withdraw!
        expect(Registration::UserRegistration.first).to be_nil
      end

      it "raises error if campaign is closed" do
        campaign.update!(status: :closed)
        service = described_class.new(campaign, user, item)
        result = service.withdraw!
        expect(result.success?).to be(false)
        expect(result.errors).to include(I18n.t("registration.messages.campaign_not_opened"))
      end
    end

    context "registered another item" do
      before do
        Registration::UserRegistration.create!(
          registration_campaign: campaign,
          registration_item: item2,
          user: user,
          status: :confirmed
        )
      end

      it "raise error if incorrect item is given" do
        service = described_class.new(campaign, user, item)
        expect do
          service.withdraw!
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "take action on the campaign with predecessor and successor" do
    let(:campaign_parent) do
      FactoryBot.create(:registration_campaign, :open)
    end
    let(:campaign_child) do
      FactoryBot.create(:registration_campaign, :open, :with_prerequisite_policy,
                        parent_campaign: campaign_parent)
    end
    let(:item_child) { campaign_child.registration_items.first }
    let(:item_parent) { campaign_parent.registration_items.first }

    let(:policy) { campaign_child.registration_policies.find_by(kind: :prerequisite_campaign) }

    before(:each) do
      Registration::UserRegistration.delete_all
    end

    it "expect id of preq policy of child match parent id" do
      expect(policy.config["prerequisite_campaign_id"]).to eq(campaign_parent.id)
    end

    it "fail to register child if parent has not been registered" do
      service = described_class.new(campaign_child, user, item_child)
      result = service.register!
      expect(result.success?).to be(false)
      expect(result.errors).to include(I18n.t("registration.messages.requirements_not_met"))
    end

    it "success to register child if parent has been registered" do
      service_parent = described_class.new(campaign_parent, user, item_parent)
      service_parent.register!
      service = described_class.new(campaign_child, user, item_child)
      result = service.register!
      expect(result.success?).to be(true)
    end
  end
  describe "campaign with cohort and tutorial items" do
    let(:campaign) do
      create(:registration_campaign, :draft, campaignable: lecture)
    end

    let(:cohort) do
      create(:cohort,
             context: seminar,
             purpose: :general,
             propagate_to_lecture: false,
             capacity: nil)
    end

    let(:tutorial) do
      create(:tutorial,
             lecture: lecture,
             capacity: 20)
    end

    let!(:item_cohort) do
      create(:registration_item,
             registration_campaign: campaign,
             registerable: cohort)
    end

    let!(:item_tutorial) do
      create(:registration_item,
             registration_campaign: campaign,
             registerable: tutorial)
    end

    before do
      campaign.update!(status: :open)
    end

    it "allows registering for cohort" do
      service = described_class.new(campaign, user, item_cohort)
      result = service.register!
      expect(result.success?).to be(true)
      registration = Registration::UserRegistration.last
      expect(registration.registration_item).to eq(item_cohort)
      expect(registration.status).to eq("confirmed")
    end

    it "blocks registering for cohort when tutorial registration is confirmed" do
      Registration::UserRegistration.create!(
        registration_campaign: campaign,
        registration_item: item_tutorial,
        user: user,
        status: :confirmed
      )
      service = described_class.new(campaign, user, item_cohort)
      result = service.register!
      expect(result.success?).to be(false)
      expect(result.errors).to include(I18n.t("registration.messages.already_registered"))
    end
  end
end
