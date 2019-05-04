require 'rails_helper'

RSpec.describe Lesson, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:lesson)).to be_valid
  end
  it 'has a valid factory for including tags' do
    expect(FactoryBot.build(:lesson, :with_tags)).to be_valid
  end
  it 'is invalid without a lecture' do
    lesson = FactoryBot.build(:lesson, lecture: nil, date: Date.new(2017, 1, 1))
    expect(lesson).to be_invalid
  end
  it 'is invalid without a date' do
    lesson = FactoryBot.build(:lesson, date: nil)
    expect(lesson).to be_invalid
  end
  it 'is invalid with an invalid date' do
    lesson = FactoryBot.build(:lesson, date: 3.14)
    expect(lesson).to be_invalid
  end
  it 'is invalid with a date that is not within the term' do
    term = FactoryBot.create(:term)
    date = term.begin_date + 1.year
    lecture = FactoryBot.create(:lecture, term: term)
    lesson = FactoryBot.build(:lesson, lecture: lecture, date: date)
    expect(lesson).to be_invalid
  end
  it 'is invalid without a number' do
    lesson = FactoryBot.build(:lesson, number: nil)
    expect(lesson).to be_invalid
  end
  it 'is invalid if number is not an integer but a string' do
    lesson = FactoryBot.build(:lesson, number: 'hello')
    expect(lesson).to be_invalid
  end
  it 'is invalid if number is not an integer but a float' do
    lesson = FactoryBot.build(:lesson, number: 2017.25)
    expect(lesson).to be_invalid
  end
  it 'is invalid if number is lower than 1' do
    lesson = FactoryBot.build(:lesson, number: 0)
    expect(lesson).to be_invalid
  end
  it 'is invalid if number is higher than 999' do
    lesson = FactoryBot.build(:lesson, number: 1000)
    expect(lesson).to be_invalid
  end
  it 'is invalid with duplicate lecture and number' do
    lecture = FactoryBot.build(:lecture)
    FactoryBot.create(:lesson, lecture: lecture, number: 42)
    duplicate_lesson = FactoryBot.build(:lesson, lecture: lecture, number: 42)
    expect(duplicate_lesson).to be_invalid
  end
  describe '#term' do
    it 'returns the correct term' do
      term = FactoryBot.create(:term)
      lecture = FactoryBot.create(:lecture, term: term)
      lesson = FactoryBot.build(:lesson, lecture: lecture)
      expect(lesson.term).to eq(term)
    end
  end
  describe '#course' do
    it 'returns the correct course' do
      course = FactoryBot.create(:course)
      lecture = FactoryBot.create(:lecture, course: course)
      lesson = FactoryBot.build(:lesson, lecture: lecture)
      expect(lesson.course).to eq(course)
    end
  end
  describe '#date_localized' do
    it 'returns the correct date in german spelling' do
      term = FactoryBot.create(:term, year: 2199, season: 'SS')
      lecture = FactoryBot.create(:lecture, term: term)
      lesson = FactoryBot.build(:lesson, lecture: lecture, date: Date.new(2199, 7, 5))
      expect(lesson.date_localized).to eq('5.7.2199')
    end
  end
  describe '#to_label' do
    it 'returns the correct label' do
      term = FactoryBot.create(:term, year: 2199, season: 'SS')
      lecture = FactoryBot.create(:lecture, term: term)
      lesson = FactoryBot.build(:lesson, lecture: lecture, number: 8, date: Date.new(2199, 7, 5))
      expect(lesson.to_label).to eq('Nr. 8, 5.7.2199')
    end
  end
  describe '#title' do
    it 'returns the correct title' do
      term = FactoryBot.create(:term, year: 2199, season: 'SS')
      lecture = FactoryBot.create(:lecture, term: term)
      lesson = FactoryBot.build(:lesson, lecture: lecture, number: 8, date: Date.new(2199, 7, 5))
      expect(lesson.title).to eq('Sitzung 8, 5.7.2199')
    end
  end
  describe '#section_titles' do
    it 'returns the correct section_titles' do
      lecture = FactoryBot.create(:lecture)
      chapter = FactoryBot.create(:chapter, lecture: lecture)
      first_section = FactoryBot.create(:section, chapter: chapter, title: 'Unsinn')
      second_section = FactoryBot.create(:section, chapter: chapter, title: 'schon wieder')
      lesson = FactoryBot.build(:lesson, lecture: lecture, sections: [first_section, second_section])
      expect(lesson.section_titles).to eq('Unsinn, schon wieder')
    end
  end
  describe '#description' do
    it 'returns the correct description' do
      course = FactoryBot.create(:course, title: 'Usual bs')
      term = FactoryBot.create(:term, year: 2199, season: 'SS')
      lecture = FactoryBot.create(:lecture, course: course, term: term)
      lesson = FactoryBot.build(:lesson, lecture: lecture, number: 8, date: Date.new(2199, 7, 5))
      expect(lesson.description).to eq({ general: 'Usual bs, SS 2199', specific: 'Sitzung 8, 5.7.2199' })
    end
  end
end
