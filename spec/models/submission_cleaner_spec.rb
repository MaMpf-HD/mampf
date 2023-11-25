# frozen_string_literal: true

require "rails_helper"

RSpec.describe SubmissionCleaner, type: :model do
  it "has a factory" do
    expect(FactoryBot.build(:submission_cleaner))
      .to be_kind_of(SubmissionCleaner)
  end

  describe "with sample submissions" do
    before :all do
      Term.destroy_all
      ActionMailer::Base.deliveries = []
      @term1 = FactoryBot.create(:term, year: Time.zone.today.year, season: "SS")
      @term2 = FactoryBot.create(:term, year: Time.zone.today.year - 1, season: "WS")
      @lecture1 = FactoryBot.create(:lecture)
      @lecture2 = FactoryBot.create(:lecture)
      tutorial1 = FactoryBot.create(:tutorial, :with_tutors, lecture: @lecture1)
      tutorial2 = FactoryBot.create(:tutorial, :with_tutors, lecture: @lecture2)
      tutorial3 = FactoryBot.create(:tutorial, :with_tutors, lecture: @lecture2)
      assignment1 = FactoryBot.create(:assignment,
                                      lecture: @lecture1,
                                      deletion_date: Time.zone.today + 14.days)
      assignment2 = FactoryBot.create(:assignment,
                                      lecture: @lecture2,
                                      deletion_date: Time.zone.today + 14.days)
      assignment3 = FactoryBot.create(:assignment,
                                      lecture: @lecture2,
                                      deletion_date: Time.zone.today + 21.days)
      @user1 = FactoryBot.create(:confirmed_user,
                                 locale: I18n.available_locales.first)
      @user2 = FactoryBot.create(:confirmed_user,
                                 locale: I18n.available_locales.first)
      @user3 = FactoryBot.create(:confirmed_user,
                                 locale: I18n.available_locales.first)
      @submission1 = FactoryBot.create(:submission,
                                       tutorial: tutorial1,
                                       assignment: assignment1)
      @submission1.users << @user1
      @submission2 = FactoryBot.create(:submission,
                                       tutorial: tutorial2,
                                       assignment: assignment2)
      @submission2.users << @user2
      @submission3 = FactoryBot.create(:submission,
                                       tutorial: tutorial3,
                                       assignment: assignment3)
      @submission3.users << @user3
    end

    describe "#set_attributes" do
      it "sends info emails correctly" do
        cleaner = FactoryBot.build(:submission_cleaner,
                                   date: Time.zone.today)

        # NOTE: mail to two submitters is counted as one mail
        expect do
          cleaner.clean!
        end.to change { ActionMailer::Base.deliveries.count }.by(3)
      end

      it "sends info and reminder emails correctly" do
        cleaner = FactoryBot.build(:submission_cleaner,
                                   date: Time.zone.today + 7.days)

        expect do
          cleaner.clean!
        end.to change { ActionMailer::Base.deliveries.count }.by(5)
      end

      it "sends deletion emails correctly (example 1)" do
        cleaner = FactoryBot.build(:submission_cleaner,
                                   date: Time.zone.today + 14.days)

        expect do
          cleaner.clean!
        end.to change { ActionMailer::Base.deliveries.count }.by(5)
      end

      it "sends deletion emails correctly (example 2)" do
        cleaner = FactoryBot.build(:submission_cleaner,
                                   date: Time.zone.today + 21.days)

        expect do
          cleaner.clean!
        end.to change { ActionMailer::Base.deliveries.count }.by(2)
      end
    end

    describe "#clean!" do
      it "destroys submissions correctly (example 1)" do
        cleaner = FactoryBot.build(:submission_cleaner,
                                   date: Time.zone.today + 14.days)
        cleaner.clean!

        expect(Submission.all.size).to be(1)
      end

      it "destroys submissions correctly (example 2)" do
        cleaner = FactoryBot.build(:submission_cleaner,
                                   date: Time.zone.today + 21.days)
        cleaner.clean!

        expect(Submission.all.size).to be(2)
      end

      it "does not destroy submissions if no assignments to be deleted" do
        cleaner = FactoryBot.build(:submission_cleaner,
                                   date: Time.zone.today + 20.days)
        cleaner.clean!

        expect(Submission.all.size).to be(3)
      end
    end
  end
end
