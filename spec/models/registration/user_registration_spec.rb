require "rails_helper"

RSpec.describe(Registration::UserRegistration, type: :model) do
  describe "factory" do
    it "creates a valid default user registration" do
      user_registration = FactoryBot.create(:registration_user_registration)
      expect(user_registration).to be_valid
      expect(user_registration.preference_rank).to be_nil
      expect(user_registration.registration_campaign.allocation_mode).to eq("first_come_first_serve")
    end

    it "creates a valid FCFS user registration" do
      user_registration = FactoryBot.create(:registration_user_registration, :fcfs)
      expect(user_registration).to be_valid
      expect(user_registration.preference_rank).to be_nil
      expect(user_registration.status).to eq("confirmed")
      expect(user_registration.registration_campaign.allocation_mode).to eq("first_come_first_serve")
    end

    it "creates a valid preference-based user registration" do
      user_registration = FactoryBot.create(:registration_user_registration, :preference_based)
      expect(user_registration).to be_valid
      expect(user_registration.preference_rank).to eq(1)
      expect(user_registration.status).to eq("pending")
      expect(user_registration.registration_campaign.allocation_mode).to eq("preference_based")
    end
  end

  describe "validations for preference-based campaigns" do
    let(:campaign) { FactoryBot.create(:registration_campaign, :preference_based) }
    let(:user) { FactoryBot.create(:user) }
    let(:item) { FactoryBot.create(:registration_item, registration_campaign: campaign) }

    it "requires preference_rank" do
      registration = FactoryBot.build(:registration_user_registration,
                                      registration_campaign: campaign,
                                      user: user,
                                      registration_item: item,
                                      preference_rank: nil)
      expect(registration).not_to be_valid
      expect(registration.errors[:preference_rank]).to be_present
    end

    it "ensures preference_rank is unique per user and campaign" do
      FactoryBot.create(:registration_user_registration,
                        registration_campaign: campaign,
                        user: user,
                        registration_item: item,
                        preference_rank: 1)

      duplicate = FactoryBot.build(:registration_user_registration,
                                   registration_campaign: campaign,
                                   user: user,
                                   preference_rank: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:preference_rank]).to be_present
    end

    it "allows same preference_rank for different users" do
      other_user = FactoryBot.create(:user)
      FactoryBot.create(:registration_user_registration,
                        registration_campaign: campaign,
                        user: user,
                        registration_item: item,
                        preference_rank: 1)

      other_registration = FactoryBot.build(:registration_user_registration,
                                            registration_campaign: campaign,
                                            user: other_user,
                                            registration_item: item,
                                            preference_rank: 1)
      expect(other_registration).to be_valid
    end

    it "allows same user to have different ranks in same campaign" do
      FactoryBot.create(:registration_user_registration,
                        registration_campaign: campaign,
                        user: user,
                        registration_item: item,
                        preference_rank: 1)

      second_registration = FactoryBot.build(:registration_user_registration,
                                             registration_campaign: campaign,
                                             user: user,
                                             registration_item: item,
                                             preference_rank: 2)
      expect(second_registration).to be_valid
    end
  end

  describe "validations for FCFS campaigns" do
    let(:campaign) { FactoryBot.create(:registration_campaign, :first_come_first_serve) }
    let(:user) { FactoryBot.create(:user) }
    let(:item) { FactoryBot.create(:registration_item, registration_campaign: campaign) }

    it "requires preference_rank to be absent" do
      registration = FactoryBot.build(:registration_user_registration,
                                      registration_campaign: campaign,
                                      user: user,
                                      registration_item: item,
                                      preference_rank: 1)
      expect(registration).not_to be_valid
      expect(registration.errors[:preference_rank]).to be_present
    end

    it "allows preference_rank to be nil" do
      registration = FactoryBot.build(:registration_user_registration,
                                      registration_campaign: campaign,
                                      user: user,
                                      registration_item: item,
                                      preference_rank: nil)
      expect(registration).to be_valid
    end

    it "ensures user can only register once per campaign" do
      FactoryBot.create(:registration_user_registration,
                        registration_campaign: campaign,
                        user: user,
                        registration_item: item,
                        preference_rank: nil)

      duplicate = FactoryBot.build(:registration_user_registration,
                                   registration_campaign: campaign,
                                   user: user,
                                   preference_rank: nil)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to be_present
    end

    it "allows different users to register for same campaign" do
      other_user = FactoryBot.create(:user)
      FactoryBot.create(:registration_user_registration,
                        registration_campaign: campaign,
                        user: user,
                        registration_item: item,
                        preference_rank: nil)

      other_registration = FactoryBot.build(:registration_user_registration,
                                            registration_campaign: campaign,
                                            user: other_user,
                                            registration_item: item,
                                            preference_rank: nil)
      expect(other_registration).to be_valid
    end
  end
end
