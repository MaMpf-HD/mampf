require 'rails_helper'

RSpec.describe Lesson, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:lesson)).to be_valid
  end
  it 'has a valid factory for including tags' do
    expect(FactoryBot.build(:lesson, :with_tags)).to be_valid
  end
  it 'is invalid without a date' do
    lesson = FactoryBot.build(:lesson, date: nil)
    expect(lesson).to be_invalid
  end
  it 'is invalid with an invalid date' do
    lesson = FactoryBot.build(:lesson, date: 3.14)
    expect(lesson).to be_invalid
  end
  it 'is invalid without a number' do
    lesson = FactoryBot.build(:lesson, number: nil)
    expect(lesson).to be_invalid
  end
  it 'is invalid if number is not an integer' do
    lesson = FactoryBot.build(:lesson, number: 'hello')
    expect(lesson).to be_invalid
  end
  it 'is invalid if year is not an integer' do
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
end
