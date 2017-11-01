require 'rails_helper'

RSpec.describe Chapter, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:chapter)).to be_valid
  end
  it 'has a valid factory for including sections' do
    expect(FactoryBot.build(:chapter, :with_sections)).to be_valid
  end
  it 'is invalid without a title' do
    chapter = FactoryBot.build(:chapter, title: nil)
    expect(chapter).to be_invalid
  end
  it 'is invalid without a number' do
    chapter = FactoryBot.build(:chapter, number: nil)
    expect(chapter).to be_invalid
  end
  it 'is invalid with duplicate lecture and number' do
    lecture = FactoryBot.build(:lecture)
    FactoryBot.create(:chapter, lecture: lecture, number: 42)
    duplicate_chapter = FactoryBot.build(:chapter, lecture: lecture,
                                                    number: 42)
    expect(duplicate_chapter).to be_invalid
  end
  it 'is invalid if number is not an integer' do
    chapter = FactoryBot.build(:chapter, number: 'hello')
    expect(chapter).to be_invalid
  end
  it 'is invalid if number is lower than 0' do
    chapter = FactoryBot.build(:chapter, number: -1)
    expect(chapter).to be_invalid
  end
  it 'is invalid if number is higher than 999' do
    chapter = FactoryBot.build(:chapter, number: 1000)
    expect(chapter).to be_invalid
  end
end
