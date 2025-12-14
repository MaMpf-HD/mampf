require "rails_helper"

RSpec.describe(Registration::UserRegistration::LectureFcfsEditService, type: :service) do
  let(:user) { FactoryBot.create(:user, email: "student@mampf.edu") }
  let(:lecture) { FactoryBot.create(:lecture, teacher: teacher) }

  describe "register lecture campaign" do
    let(:campaign) { FactoryBot.create(:registration_campaign, :open, :for_lecture_enrollment) }
    let(:item) { campaign.registration_items.first }

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

    it "creates a confirmed registration when validations pass when rejected registration existed" do
      Registration::UserRegistration.create!(
        registration_campaign: campaign,
        registration_item: item,
        user: user,
        status: :rejected
      )
      service = described_class.new(campaign, user, item)
      service.register!
      registration = Registration::UserRegistration.last
      expect(registration.user).to eq(user)
      expect(registration.registration_campaign).to eq(campaign)
      expect(registration.registration_item).to eq(item)
      expect(registration.status).to eq("confirmed")
    end

    it "raises error if campaign is closed" do
      campaign.update!(status: :draft)
      service = described_class.new(campaign, user, item)

      result = service.register!
      expect(result.success?).to be(false)
      expect(result.errors).to include(I18n.t("registration.messages.campaign_not_opened"))
    end

    it "raises error if user already registered" do
      Registration::UserRegistration.create!(
        registration_campaign: campaign,
        registration_item: item,
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

  describe "widthdraw lecture campaign" do
    let(:campaign) { FactoryBot.create(:registration_campaign, :open, :for_lecture_enrollment) }
    let(:item) { campaign.registration_items.first }
    before do
      # Create a confirmed registration
      Registration::UserRegistration.create!(
        registration_campaign: campaign,
        registration_item: item,
        user: user,
        status: :confirmed
      )
    end

    it "fully delete registration when validations pass" do
      service = described_class.new(campaign, user, item)
      service.withdraw!
      registration = Registration::UserRegistration.last
      expect(registration).to be_nil
    end

    it "raises error if campaign is closed" do
      campaign.update!(status: :draft)
      service = described_class.new(campaign, user, item)

      result = service.withdraw!
      expect(result.success?).to be(false)
      expect(result.errors).to include(I18n.t("registration.messages.campaign_not_opened"))
    end
  end

  describe "register tutorial campaign" do
    let(:campaign) { FactoryBot.create(:registration_campaign, :open, :for_tutorial_enrollment) }
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

    it "creates a confirmed registration when validations pass, case has rejected user registration" do
      Registration::UserRegistration.create!(
        registration_campaign: campaign,
        registration_item: item2,
        user: user,
        status: :rejected
      )

      service = described_class.new(campaign, user, item)
      service.register!
      registration = Registration::UserRegistration.last

      expect(registration.user).to eq(user)
      expect(registration.registration_campaign).to eq(campaign)
      expect(registration.registration_item).to eq(item)
      expect(registration.status).to eq("confirmed")
    end

    it "raises error if campaign is closed" do
      campaign.update!(status: :draft)
      service = described_class.new(campaign, user, item)

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

  describe "withdraw tutorial campaign" do
    let(:campaign) { FactoryBot.create(:registration_campaign, :open, :for_tutorial_enrollment) }
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

      it "fully delete registration when validations pass" do
        service = described_class.new(campaign, user, item)
        service.withdraw!
        registration = Registration::UserRegistration.first
        expect(registration).to be_nil
      end

      it "raises error if campaign is closed" do
        campaign.update!(status: :draft)
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
      FactoryBot.create(:registration_campaign, :open, :for_lecture_enrollment)
    end
    let(:campaign_child) do
      FactoryBot.create(:registration_campaign, :open, :for_lecture_enrollment,
                        :with_prerequisite_policy, parent_campaign: campaign_parent)
    end
    let(:item_child) { campaign_child.registration_items.first }
    let(:item_parent) { campaign_parent.registration_items.first }

    let(:policy) { campaign_child.registration_policies.find_by(kind: :prerequisite_campaign) }

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

    it "cannot withdraw parent if child has been registered + freely to deregister child + freely to deregister parent if child has not been registered" do
      service_parent = described_class.new(campaign_parent, user, item_parent)
      service_parent.register!
      service_child = described_class.new(campaign_child, user, item_child)
      service_child.register!

      # withdraw parent if child has been registered
      service_parent1 = described_class.new(campaign_parent, user, item_parent)
      result1 = service_parent1.withdraw!
      expect(result1.success?).to be(false)
      expect(result1.errors).to include(I18n.t("registration.messages.dependent_campaigns_block_withdrawal", names: campaign_parent.title))

      # freely to withdraw child
      service_child1 = described_class.new(campaign_child, user, item_child)
      result2 = service_child1.withdraw!
      expect(result2.success?).to be(true)
      
      # freely to withdraw parent if child has not been registered
      service_parent2 = described_class.new(campaign_parent, user, item_parent)
      result3 = service_parent2.withdraw!
      expect(result3.success?).to be(true)
    end
  end
end
