require 'rails_helper'

RSpec.describe Lesson, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:lesson)).to be_valid
  end
  it 'has a valid factory for including tags' do
    expect(FactoryGirl.build(:lesson, :with_tags)).to be_valid
  end
  it 'is invalid without a date' do
    lesson = FactoryGirl.build(:lesson, date: nil)
    expect(lesson).to be_invalid
  end
  it 'is invalid with an invalid date' do
    lesson = FactoryGirl.build(:lesson, date: 3.14)
    expect(lesson).to be_invalid
  end
  it 'is invalid without a number' do
    lesson = FactoryGirl.build(:lesson, number: nil)
    expect(lesson).to be_invalid
  end
  it 'is invalid if number is not a number' do
    lesson = FactoryGirl.build(:lesson, number: 'hello')
    expect(lesson).to be_invalid
  end
  it 'is invalid if year is not an integer' do
    lesson = FactoryGirl.build(:lesson, number: 2017.25)
    expect(lesson).to be_invalid
  end
  it 'is invalid if number is lower than 1' do
    lesson = FactoryGirl.build(:lesson, number: 0)
    expect(lesson).to be_invalid
  end
  it 'is invalid if number is higher than 999' do
    lesson = FactoryGirl.build(:lesson, number: 1000)
    expect(lesson).to be_invalid
  end
  it 'is invalid with duplicate lecture and number' do
    lecture = FactoryGirl.build(:lecture)
    FactoryGirl.create(:lesson, lecture: lecture, number: 42)
    duplicate_lesson = FactoryGirl.build(:lesson, lecture: lecture, number: 42)
    expect(duplicate_lesson).to be_invalid
  end
end
