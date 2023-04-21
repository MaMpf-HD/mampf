# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lesson, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:valid_lesson)).to be_valid
  end

  # Test validations
  it 'is invalid without a lecture' do
    lesson = FactoryBot.build(:valid_lesson)
    lesson.lecture = nil
    expect(lesson).to be_invalid
  end
  it 'is invalid without a date' do
    lesson = FactoryBot.build(:valid_lesson)
    lesson.date = nil
    expect(lesson).to be_invalid
  end
  it 'is invalid without a section' do
    lesson = FactoryBot.build(:lesson, :with_lecture_and_date)
    expect(lesson).to be_invalid
  end

  # Test traits

  describe 'lesson with lecture and date' do
    before(:all) do
      @lesson = FactoryBot.build(:lesson, :with_lecture_and_date)
    end
    it 'is invalid when taken alone' do
      expect(@lesson).to be_invalid
    end
    it 'has a lecture' do
      expect(@lesson.lecture).to be_kind_of(Lecture)
    end
  end

  describe 'lesson with lecture, date and section' do
    before(:all) do
      @lesson = FactoryBot.build(:lesson, :with_lecture_date_and_section)
    end
    it 'has a valid factory' do
      expect(@lesson).to be_valid
    end
    it 'has a lecture' do
      expect(@lesson.lecture).to be_kind_of(Lecture)
    end
    it 'has one section' do
      expect(@lesson.sections.size).to eq 1
    end
  end

  # Test methods -- NEEDS TO BE REFACTORED

  # describe '#term' do
  #   it 'returns the correct term' do
  #     term = FactoryBot.create(:term)
  #     lecture = FactoryBot.create(:lecture, term: term)
  #     lesson = FactoryBot.build(:lesson, lecture: lecture)
  #     expect(lesson.term).to eq(term)
  #   end
  # end
  # describe '#course' do
  #   it 'returns the correct course' do
  #     course = FactoryBot.create(:course)
  #     lecture = FactoryBot.create(:lecture, course: course)
  #     lesson = FactoryBot.build(:lesson, lecture: lecture)
  #     expect(lesson.course).to eq(course)
  #   end
  # end
  # describe '#date_localized' do
  #   it 'returns the correct date in german spelling' do
  #     term = FactoryBot.create(:term, year: 2199, season: 'SS')
  #     lecture = FactoryBot.create(:lecture, term: term)
  #     lesson = FactoryBot.build(:lesson, lecture: lecture,
  #                               date: Date.new(2199, 7, 5))
  #     expect(lesson.date_localized).to eq('5.7.2199')
  #   end
  # end
  # describe '#to_label' do
  #   it 'returns the correct label' do
  #     term = FactoryBot.create(:term, year: 2199, season: 'SS')
  #     lecture = FactoryBot.create(:lecture, term: term)
  #     lesson = FactoryBot.build(:lesson, lecture: lecture, number: 8,
  #                               date: Date.new(2199, 7, 5))
  #     expect(lesson.to_label).to eq('Nr. 8, 5.7.2199')
  #   end
  # end
  # describe '#title' do
  #   it 'returns the correct title' do
  #     term = FactoryBot.create(:term, year: 2199, season: 'SS')
  #     lecture = FactoryBot.create(:lecture, term: term)
  #     lesson = FactoryBot.build(:lesson, lecture: lecture, number: 8,
  #                               date: Date.new(2199, 7, 5))
  #     expect(lesson.title).to eq('Sitzung 8, 5.7.2199')
  #   end
  # end
  # describe '#section_titles' do
  #   it 'returns the correct section_titles' do
  #     lecture = FactoryBot.create(:lecture)
  #     chapter = FactoryBot.create(:chapter, lecture: lecture)
  #     first_section = FactoryBot.create(:section, chapter: chapter,
  #                                       title: 'Unsinn')
  #     second_section = FactoryBot.create(:section, chapter: chapter,
  #                                        title: 'schon wieder')
  #     lesson = FactoryBot.build(:lesson, lecture: lecture,
  #                               sections: [first_section, second_section])
  #     expect(lesson.section_titles).to eq('Unsinn, schon wieder')
  #   end
  # end
  # describe '#description' do
  #   it 'returns the correct description' do
  #     course = FactoryBot.create(:course, title: 'Usual bs')
  #     term = FactoryBot.create(:term, year: 2199, season: 'SS')
  #     lecture = FactoryBot.create(:lecture, course: course, term: term)
  #     lesson = FactoryBot.build(:lesson, lecture: lecture, number: 8
  #                               date: Date.new(2199, 7, 5))
  #     expect(lesson.description).to eq({ general: 'Usual bs, SS 2199',
  #                                        specific: 'Sitzung 8, 5.7.2199' })
  #   end
  # end
end
