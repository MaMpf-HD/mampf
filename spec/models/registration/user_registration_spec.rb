require "rails_helper"

RSpec.describe(Registration::UserRegistration, type: :model) do
  describe "factory" do
    it "creates a valid default user registration" do
      user_registration = FactoryBot.create(:registration_user_registration)
      expect(user_registration).to be_valid
      expect(user_registration.preference_rank).to be_nil
      expect(user_registration.registration_campaign.allocation_mode)
        .to eq("first_come_first_served")
    end

    it "creates a valid FCFS user registration" do
      user_registration = FactoryBot.create(:registration_user_registration, :fcfs)
      expect(user_registration).to be_valid
      expect(user_registration.preference_rank).to be_nil
      expect(user_registration.status).to eq("confirmed")
      expect(user_registration.registration_campaign.allocation_mode)
        .to eq("first_come_first_served")
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

    it "requires preference_rank for pending registrations" do
      registration = FactoryBot.build(:registration_user_registration,
                                      registration_campaign: campaign,
                                      user: user,
                                      registration_item: item,
                                      preference_rank: nil,
                                      status: :pending)
      expect(registration).not_to be_valid
      expect(registration.errors[:preference_rank]).to be_present
    end

    it "allows nil preference_rank for confirmed registrations (forced assignments)" do
      registration = FactoryBot.build(:registration_user_registration,
                                      registration_campaign: campaign,
                                      user: user,
                                      registration_item: item,
                                      preference_rank: nil,
                                      status: :confirmed)
      expect(registration).to be_valid
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
                                   registration_item: item,
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
    let(:lecture) { FactoryBot.create(:lecture) }
    let(:campaign) do
      FactoryBot.create(:registration_campaign, :first_come_first_served, campaignable: lecture)
    end
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

    describe "ensures user can only register once per campaign" do
      let(:seminar) { create(:seminar) }
      let(:campaign_seminar) { create(:registration_campaign, campaignable: seminar) }

      it "for tutorial items" do
        FactoryBot.create(:registration_user_registration,
                          registration_campaign: campaign,
                          user: user,
                          registration_item: item,
                          preference_rank: nil)

        duplicate = FactoryBot.build(:registration_user_registration,
                                     registration_campaign: campaign,
                                     user: user,
                                     registration_item: item,
                                     preference_rank: nil)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to be_present
      end

      it "for talk items" do
        item_talk = create(:registration_item, registration_campaign: campaign_seminar,
                                               registerable: create(:talk, lecture: seminar))
        FactoryBot.create(:registration_user_registration,
                          registration_campaign: campaign_seminar,
                          user: user,
                          registration_item: item_talk,
                          preference_rank: nil)

        duplicate = FactoryBot.build(:registration_user_registration,
                                     registration_campaign: campaign_seminar,
                                     user: user,
                                     registration_item: item_talk,
                                     preference_rank: nil)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:user_id]).to be_present
      end

      it "for cohort items" do
        cohort = create(:cohort, context: seminar, propagate_to_lecture: false, capacity: nil)

        item_cohort = create(:registration_item, registration_campaign: campaign_seminar,
                                                 registerable: cohort)
        FactoryBot.create(:registration_user_registration,
                          registration_campaign: campaign_seminar,
                          user: user,
                          registration_item: item_cohort,
                          preference_rank: nil)

        duplicate = FactoryBot.build(:registration_user_registration,
                                     registration_campaign: campaign_seminar,
                                     user: user,
                                     registration_item: item_cohort,
                                     preference_rank: nil)
        expect(duplicate).not_to be_valid
      end
    end

    context "in tutorial campaign with many types of items" do
      let(:cohort1) do
        create(:cohort, context: lecture, propagate_to_lecture: false, capacity: nil)
      end
      let(:cohort2) do
        create(:cohort, context: lecture, propagate_to_lecture: false, capacity: nil)
      end
      let(:item_cohort1) do
        create(:registration_item, registration_campaign: campaign,
                                   registerable: cohort1)
      end
      let(:item_cohort2) do
        create(:registration_item, registration_campaign: campaign,
                                   registerable: cohort2)
      end
      let(:item_tutorial2) do
        FactoryBot.create(:registration_item, registration_campaign: campaign)
      end

      it "with existing registration for cohort, can register another tutorial" do
        FactoryBot.create(:registration_user_registration,
                          registration_campaign: campaign,
                          user: user,
                          registration_item: item_cohort1,
                          preference_rank: nil)

        tutorial_registration = FactoryBot.build(:registration_user_registration,
                                                 registration_campaign: campaign,
                                                 user: user,
                                                 registration_item: item,
                                                 preference_rank: nil)
        expect(tutorial_registration).to be_valid
      end

      it "with existing registration for tutorial, can register another cohort" do
        FactoryBot.create(:registration_user_registration,
                          registration_campaign: campaign,
                          user: user,
                          registration_item: item,
                          preference_rank: nil)

        cohort_registration = FactoryBot.build(:registration_user_registration,
                                               registration_campaign: campaign,
                                               user: user,
                                               registration_item: item_cohort1,
                                               preference_rank: nil)
        expect(cohort_registration).to be_valid
      end

      it "with existing registration for cohort, can register another cohort" do
        FactoryBot.create(:registration_user_registration,
                          registration_campaign: campaign,
                          user: user,
                          registration_item: item_cohort1,
                          preference_rank: nil)

        cohort_registration = FactoryBot.build(:registration_user_registration,
                                               registration_campaign: campaign,
                                               user: user,
                                               registration_item: item_cohort2,
                                               preference_rank: nil)
        expect(cohort_registration).to be_valid
      end

      it "with existing registration for tutorial, cannot register another tutorial" do
        FactoryBot.create(:registration_user_registration,
                          registration_campaign: campaign,
                          user: user,
                          registration_item: item,
                          preference_rank: nil)

        tutorial_registration = FactoryBot.build(:registration_user_registration,
                                                 registration_campaign: campaign,
                                                 user: user,
                                                 registration_item: item_tutorial2,
                                                 preference_rank: nil)
        expect(tutorial_registration).not_to be_valid
      end
    end

    context "in seminar with many types of items" do
      let(:seminar) { create(:seminar) }
      let(:campaign_seminar) { create(:registration_campaign, campaignable: seminar) }
      let(:cohort1) do
        create(:cohort, context: seminar, propagate_to_lecture: false, capacity: nil)
      end
      let(:cohort2) do
        create(:cohort, context: seminar, propagate_to_lecture: false, capacity: nil)
      end
      let(:item_cohort1) do
        create(:registration_item, registration_campaign: campaign_seminar,
                                   registerable: cohort1)
      end
      let(:item_cohort2) do
        create(:registration_item, registration_campaign: campaign_seminar,
                                   registerable: cohort2)
      end
      let(:item_talk1) do
        create(:registration_item, registration_campaign: campaign_seminar,
                                   registerable: create(:talk, lecture: seminar))
      end
      let(:item_talk2) do
        create(:registration_item, registration_campaign: campaign_seminar,
                                   registerable: create(:talk, lecture: seminar))
      end

      it "with existing registration for cohort, can register another talk" do
        FactoryBot.create(:registration_user_registration,
                          registration_campaign: campaign_seminar,
                          user: user,
                          registration_item: item_cohort1,
                          preference_rank: nil)

        talk_registration = FactoryBot.build(:registration_user_registration,
                                             registration_campaign: campaign_seminar,
                                             user: user,
                                             registration_item: item_talk1,
                                             preference_rank: nil)
        expect(talk_registration).to be_valid
      end

      it "with existing registration for talk, can register another cohort" do
        FactoryBot.create(:registration_user_registration,
                          registration_campaign: campaign_seminar,
                          user: user,
                          registration_item: item_talk1,
                          preference_rank: nil)

        cohort_registration = FactoryBot.build(:registration_user_registration,
                                               registration_campaign: campaign_seminar,
                                               user: user,
                                               registration_item: item_cohort1,
                                               preference_rank: nil)
        expect(cohort_registration).to be_valid
      end

      it "with existing registration for cohort, can register another cohort" do
        FactoryBot.create(:registration_user_registration,
                          registration_campaign: campaign_seminar,
                          user: user,
                          registration_item: item_cohort1,
                          preference_rank: nil)

        cohort_registration = FactoryBot.build(:registration_user_registration,
                                               registration_campaign: campaign_seminar,
                                               user: user,
                                               registration_item: item_cohort2,
                                               preference_rank: nil)
        expect(cohort_registration).to be_valid
      end

      it "with existing registration for talk, cannot register another talk" do
        FactoryBot.create(:registration_user_registration,
                          registration_campaign: campaign_seminar,
                          user: user,
                          registration_item: item_talk1,
                          preference_rank: nil)

        talk_registration = FactoryBot.build(:registration_user_registration,
                                             registration_campaign: campaign_seminar,
                                             user: user,
                                             registration_item: item_talk2,
                                             preference_rank: nil)
        expect(talk_registration).not_to be_valid
      end
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

  describe "counter cache callbacks" do
    let(:user) { FactoryBot.create(:user) }

    context "with FCFS campaign (confirmed by default)" do
      let(:campaign) { FactoryBot.create(:registration_campaign, :first_come_first_served) }
      let(:item) { FactoryBot.create(:registration_item, registration_campaign: campaign) }

      it "increments counter on creation" do
        expect do
          FactoryBot.create(:registration_user_registration, :fcfs,
                            registration_campaign: campaign,
                            registration_item: item,
                            user: user)
        end.to change { item.reload.confirmed_registrations_count }.by(1)
      end

      it "decrements counter on destruction" do
        registration = FactoryBot.create(:registration_user_registration, :fcfs,
                                         registration_campaign: campaign,
                                         registration_item: item,
                                         user: user)
        expect do
          registration.destroy
        end.to change { item.reload.confirmed_registrations_count }.by(-1)
      end

      it "decrements counter when status changes to rejected" do
        registration = FactoryBot.create(:registration_user_registration, :fcfs,
                                         registration_campaign: campaign,
                                         registration_item: item,
                                         user: user)
        expect do
          registration.update(status: :rejected)
        end.to change { item.reload.confirmed_registrations_count }.by(-1)
      end
    end

    context "with preference-based campaign (pending by default)" do
      let(:campaign) { FactoryBot.create(:registration_campaign, :preference_based) }
      let(:item) { FactoryBot.create(:registration_item, registration_campaign: campaign) }

      it "does not increment counter on creation" do
        expect do
          FactoryBot.create(:registration_user_registration, :preference_based,
                            registration_campaign: campaign,
                            registration_item: item,
                            user: user,
                            preference_rank: 1)
        end.not_to(change { item.reload.confirmed_registrations_count })
      end

      it "increments counter when status changes to confirmed" do
        registration = FactoryBot.create(:registration_user_registration, :preference_based,
                                         registration_campaign: campaign,
                                         registration_item: item,
                                         user: user,
                                         preference_rank: 1)
        expect do
          registration.update(status: :confirmed)
        end.to change { item.reload.confirmed_registrations_count }.by(1)
      end

      it "does not decrement counter on destruction" do
        registration = FactoryBot.create(:registration_user_registration, :preference_based,
                                         registration_campaign: campaign,
                                         registration_item: item,
                                         user: user,
                                         preference_rank: 1)
        expect do
          registration.destroy
        end.not_to(change { item.reload.confirmed_registrations_count })
      end
    end
  end

  describe "integrity validations" do
    it "ensures registration item belongs to the same campaign" do
      campaign1 = FactoryBot.create(:registration_campaign)
      campaign2 = FactoryBot.create(:registration_campaign)
      item_from_campaign2 = FactoryBot.create(:registration_item, registration_campaign: campaign2)

      registration = FactoryBot.build(:registration_user_registration,
                                      registration_campaign: campaign1,
                                      registration_item: item_from_campaign2)

      expect(registration).not_to be_valid
      error_msg = I18n.t("activerecord.errors.models.registration/user_registration.attributes." \
                         "registration_item.must_belong_to_same_campaign")
      expect(registration.errors[:registration_item]).to include(error_msg)
    end
  end

  describe "immutability" do
    let(:registration) { FactoryBot.create(:registration_user_registration) }

    it "prevents updating registration_item_id" do
      new_item = FactoryBot.create(:registration_item)

      expect do
        registration.update(registration_item_id: new_item.id)
      end.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end
  end
end
