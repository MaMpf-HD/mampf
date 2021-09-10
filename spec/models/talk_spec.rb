# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Talk, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:valid_talk)).to be_valid
  end

  # Test validations
  it 'is invalid without a lecture' do
    talk = FactoryBot.build(:valid_talk)
    talk.lecture = nil
    expect(talk).to be_invalid
  end
  it 'is invalid without a title' do
    talk = FactoryBot.build(:valid_talk)
    talk.title = nil
    expect(talk).to be_invalid
  end

  # Test traits

  describe 'talk with date' do
    before(:all) do
      @talk = FactoryBot.build(:valid_talk, :with_date)
    end
    it 'is valid' do
      expect(@talk).to be_valid
    end
    it 'has a date' do
      expect(@talk.dates.first).to be_kind_of(Date)
    end
  end

  describe '#talk' do
    it 'returns itself' do
      talk = FactoryBot.build(:talk)
      expect(talk.talk).to eq talk
    end
  end

  describe '#lesson' do
    it 'returns nil' do
      talk = FactoryBot.build(:talk)
      expect(talk.lesson).to be_nil
    end
  end

  context 'title methods' do
    before :all do
      I18n.locale = 'de'
      course = FactoryBot.build(:course, title: 'Algebra 1',
                                short_title: 'Alg1')
      term = FactoryBot.build(:term, season: 'SS', year: 2020)
      lecture = FactoryBot.build(:lecture, course: course, term: term)
      FactoryBot.create(:talk, lecture: lecture, title: 'total bs')
      @talk = FactoryBot.create(:talk, lecture: lecture,
                                      title: 'even more bs')
    end

    describe '#to_label' do
      it 'returns the correct label' do
        I18n.locale = 'de'
        expect(@talk.to_label).to eq 'Vortrag 2. even more bs'
      end
    end

    describe '#title_for_viewers' do
      it 'returns the correct title' do
        expect(@talk.title_for_viewers)
          .to eq '(V) Alg1 SS 20, Vortrag 2. even more bs'
      end
    end

    describe '#long_title' do
      it 'returns the correct title' do
        expect(@talk.long_title)
          .to eq '(V) Alg1 SS 20, Vortrag 2. even more bs'
      end
    end

    describe '#local_title_for_viewers' do
      it 'returns the correct title' do
        expect(@talk.local_title_for_viewers)
          .to eq 'Vortrag 2. even more bs'
      end
    end

    describe '#short_title_with_lecture_date' do
      it 'returns the correct title' do
        expect(@talk.short_title_with_lecture_date)
          .to eq '(V) Alg1 SS 20, Vortrag 2. even more bs'
      end
    end

    describe '#card_header' do
      it 'returns the correct title' do
        expect(@talk.card_header)
          .to eq '(V) Alg1 SS 20, Vortrag 2. even more bs'
      end
    end

    describe '#compact_title' do
      it 'returns the correct compact title' do
        expect(@talk.compact_title).to eq 'V.Alg1.SS20.V2'
      end
    end
  end

  describe '#given_by?' do
    it 'returns true if the user is a speaker of the talk' do
      talk = FactoryBot.build(:valid_talk)
      user = FactoryBot.build(:confirmed_user)
      talk.speakers << user
      expect(talk.given_by?(user)).to be true
    end
  end

  context 'locale methods' do
    before :all do
      I18n.locale = 'de'
      course = FactoryBot.build(:course, title: 'Algebra 1',
                                short_title: 'Alg1')
      term = FactoryBot.build(:term, season: 'SS', year: 2020)
      lecture = FactoryBot.build(:lecture, course: course, term: term,
                                 locale: 'br')
      @talk = FactoryBot.create(:talk, lecture: lecture)
    end

    describe '#locale_with_inheritance' do
      it 'returns the locale of the lecture' do
        expect(@talk.locale_with_inheritance).to eq 'br'
      end
    end

    describe '#locale' do
      it 'returns the locale of the lecture' do
        expect(@talk.locale).to eq 'br'
      end
    end

    describe '#published' do
      before :all do
        course = FactoryBot.build(:course)
        @lecture = FactoryBot.build(:lecture, course: course, released: 'all')
        @talk = FactoryBot.build(:talk, lecture: @lecture)
      end
      it 'returns true if the associated lecture is published' do
        expect(@talk.published?).to be true
      end
      it 'returns false if the associated lecture is not published' do
        @lecture.released = nil
        expect(@talk.published?).to be false
      end
    end
  end

  describe '#dates_localized' do
    it 'returns the correct localized dates' do
      I18n.locale = 'de'
      talk = FactoryBot.build(:valid_talk)
      talk.dates = [Date.new(2021,1,11), Date.new(2021,1,12)]
      expect(talk.dates_localized).to eq '11.01.2021, 12.01.2021'
    end
  end

  describe '#course' do
    it 'returns the course associated to the talk' do
      course = FactoryBot.build(:course)
      lecture = FactoryBot.build(:lecture, course: course, released: 'all')
      talk = FactoryBot.build(:talk, lecture: lecture)
      expect(talk.course).to eq course
    end
  end

  describe '#media_scope' do
    it 'returns the lecture associated to the talk' do
      lecture = FactoryBot.build(:lecture, released: 'all')
      talk = FactoryBot.build(:talk, lecture: lecture)
      expect(talk.media_scope).to eq lecture
    end
  end

  context 'position methods' do
    before :all do
      lecture = FactoryBot.build(:lecture)
      @talk1 = FactoryBot.create(:talk, lecture: lecture)
      @talk2 = FactoryBot.create(:talk, lecture: lecture)
      @talk3 = FactoryBot.create(:talk, lecture: lecture)
    end

    describe '#number' do
      it 'returns the number of the talk' do
        expect(@talk3.number).to eq 3
      end
    end

    describe '#previous' do
      it 'returns the previous talk if the talk is not the first one' do
        expect(@talk3.previous).to eq @talk2
      end

      it 'returns nil if the talk is the first one' do
        expect(@talk1.previous).to be nil
      end
    end

    describe '#next' do
      it 'returns the next talk if the talk is not the last one' do
        expect(@talk2.next).to eq @talk3
      end

      it 'returns nil if the talk is the last one' do
        expect(@talk3.next).to be nil
      end
    end
  end
end