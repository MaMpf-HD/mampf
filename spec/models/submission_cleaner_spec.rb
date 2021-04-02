# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmissionCleaner, type: :model do
  it 'has a factory' do
    expect(FactoryBot.build(:submission_cleaner))
      .to be_kind_of(SubmissionCleaner)
  end

  describe '#set_attributes' do
    after :each do
      @term.destroy
    end

    it 'correctly determines wether an action is possible (example 1)' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS')
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('25.3.2020'))
      cleaner.set_attributes
      expect(cleaner.advance).to be false
    end

    it 'correctly determines wether an action is possible (example 2a)' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS')
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('1.4.2021'))
      cleaner.set_attributes
      expect(cleaner.advance).to be true
    end

    it 'correctly determines wether an action is possible (example 2b)' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS')
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('1.4.2021'))
      cleaner.set_attributes
      expect(cleaner.destroy).not_to be true
    end

    it 'correctly determines wether an action is possible (example 3)' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS')
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('3.4.2021'))
      cleaner.set_attributes
      expect(cleaner.advance).to be false
    end

    it 'correctly determines wether an action is possible (example 4)' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS')
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('8.4.2021'))
      cleaner.set_attributes
      expect(cleaner.advance).to be false
    end

    it 'correctly determines wether an action is possible (example 5a)' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS',
                                submission_deletion_mail:
                                  DateTime.parse('1.4.2021 3:00'))
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('8.4.2021'))
      cleaner.set_attributes
      expect(cleaner.advance).to be true
    end

    it 'correctly determines wether an action is possible (example 5b)' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS',
                                submission_deletion_mail:
                                  DateTime.parse('1.4.2021 3:00'))
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('8.4.2021'))
      cleaner.set_attributes
      expect(cleaner.destroy).not_to be true
    end

    it 'correctly determines wether an action is possible (example 6)' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS',
                                submission_deletion_mail:
                                  DateTime.parse('1.4.2021 3:00'),
                                submission_deletion_reminder:
                                  DateTime.parse('8.4.2021 3:00'))
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('9.4.2021'))
      cleaner.set_attributes
      expect(cleaner.advance).to be false
    end

    it 'correctly determines wether an action is possible (example 7)' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS',
                                submission_deletion_mail:
                                  DateTime.parse('1.4.2021 3:00'),
                                submission_deletion_reminder:
                                  DateTime.parse('8.4.2021 3:00'))
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('9.4.2021'))
      cleaner.set_attributes
      expect(cleaner.advance).to be false
    end

    it 'correctly determines wether an action is possible (example 8a)' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS',
                                submission_deletion_mail:
                                  DateTime.parse('1.4.2021 3:00'),
                                submission_deletion_reminder:
                                  DateTime.parse('8.4.2021 3:00'))
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('15.4.2021'))
      cleaner.set_attributes
      expect(cleaner.advance).to be true
    end

    it 'correctly determines wether an action is possible (example 8b)' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS',
                                submission_deletion_mail:
                                  DateTime.parse('1.4.2021 3:00'),
                                submission_deletion_reminder:
                                  DateTime.parse('8.4.2021 3:00'))
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('15.4.2021'))
      cleaner.set_attributes
      expect(cleaner.destroy).to be true
    end

    it 'correctly determines wether an action is possible (example 8a)' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS',
                                submission_deletion_mail:
                                  DateTime.parse('1.4.2021 3:00'),
                                submission_deletion_reminder:
                                  nil)
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('15.4.2021'))
      cleaner.set_attributes
      expect(cleaner.advance).to be false
    end
  end

  describe '#clean!' do
    after :each do
      @term.destroy
    end

    it 'does nothing if the date is not right' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS')
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('28.3.2021'))
      cleaner.clean!
      @term.reload
      expect(@term.submission_deletion_mail).to be_nil
    end

    it 'updates submission_deletion_mail column on first day of next term' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS')
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('1.4.2021'))
      cleaner.clean!
      @term.reload
      expect(@term.submission_deletion_mail).not_to be_nil
    end

    it 'updates submission_deletion_reminder column one week later' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS',
                                submission_deletion_mail:
                                  DateTime.parse('1.4.2021 3:00'))
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('8.4.2021'))
      cleaner.clean!
      @term.reload
      expect(@term.submission_deletion_reminder).not_to be_nil
    end

    it 'updates submissions_deleted_at column two weeks later' do
      @term = FactoryBot.create(:term, year: 2020, season: 'WS',
                                submission_deletion_mail:
                                  DateTime.parse('1.4.2021 3:00'),
                                submission_deletion_reminder:
                                  DateTime.parse('8.4.2021 3:00'))
      cleaner = FactoryBot.build(:submission_cleaner,
                                 date: Date.parse('15.4.2021'))
      cleaner.clean!
      @term.reload
      expect(@term.submissions_deleted_at).not_to be_nil
    end
  end

  context 'with sample submissions' do

    before :all do
      Term.destroy_all
      @term = FactoryBot.create(:term, year: 2020, season: 'WS')
      @lecture = FactoryBot.create(:lecture, term: @term)
      tutorial = FactoryBot.create(:tutorial, :with_tutors, lecture: @lecture)
      assignment1 = FactoryBot.create(:assignment,
                                     lecture: @lecture,
                                     deadline: Date.parse('31.12.2020'))
      assignment2 = FactoryBot.create(:assignment,
                                      lecture: @lecture,
                                      deadline: Date.parse('31.1.2021'))
      @user1 = FactoryBot.create(:confirmed_user)
      @user2 = FactoryBot.create(:confirmed_user)
      @user3 = FactoryBot.create(:confirmed_user)
      @user4 = FactoryBot.create(:confirmed_user)
      @submission1 = FactoryBot.create(:submission,
                                      tutorial: tutorial,
                                      assignment: assignment1)
      @submission1.users << @user1
      @submission2 = FactoryBot.create(:submission,
                                      tutorial: tutorial,
                                      assignment: assignment1)
      @submission2.users << [@user2, @user3]
      @submission3 = FactoryBot.create(:submission,
                                      tutorial: tutorial,
                                      assignment: assignment2)
      @submission3.users << @user4
      @term2 = FactoryBot.create(:term, year: 2021, season: 'SS')
      lecture2 = FactoryBot.create(:lecture, term: @term2)
      tutorial2 = FactoryBot.create(:tutorial, :with_tutors, lecture: lecture2)
      assignment21 = FactoryBot.create(:assignment,
                                       lecture: lecture2,
                                       deadline: Date.parse('15.5.2021'))
      @submission21 = FactoryBot.create(:submission,
                                       tutorial: tutorial2,
                                       assignment: assignment21)
      user5 = FactoryBot.create(:confirmed_user)
      @submission21.users << [@user1, user5]
      lecture3 = FactoryBot.create(:lecture, term: @term)
    end

    describe '#set_attributes' do
      it 'sets the submissions correctly' do
        cleaner = FactoryBot.build(:submission_cleaner,
                                   date: Date.parse('1.4.2021'))
        cleaner.set_attributes
        expect(cleaner.submissions)
          .to match_array([@submission1, @submission2, @submission3])
      end

      it 'sets the submitters correctly' do
        cleaner = FactoryBot.build(:submission_cleaner,
                                   date: Date.parse('1.4.2021'))
        cleaner.set_attributes
        expect(cleaner.submitters)
          .to match_array([@user1, @user2, @user3, @user4])
      end

      it 'sets the lectures correctly' do
        cleaner = FactoryBot.build(:submission_cleaner,
                                   date: Date.parse('1.4.2021'))
        cleaner.set_attributes
        expect(cleaner.lectures).to match_array([@lecture])
      end
    end

    describe '#clean!' do
      it 'destroys submissions of the relevant term two weeks later' do
        @term.submission_deletion_mail = DateTime.parse('1.4.2021 3:00')
        @term.submission_deletion_reminder = DateTime.parse('8.4.2021 3:00')
        @term.save
        cleaner = FactoryBot.build(:submission_cleaner,
                                   date: Date.parse('15.4.2021'))
        cleaner.clean!
        @term.reload
        expect([@term.submissions.to_a, @term2.submissions.to_a])
          .to eq([[], [@submission21]])
      end
    end
  end
end