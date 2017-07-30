require 'rails_helper'

RSpec.describe Section, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:section)).to be_valid
  end
  it 'has a valid factory for including lessons' do
    expect(FactoryGirl.create(:section, :with_lessons)).to be_valid
  end
  it 'has a valid factory for including tags' do
    expect(FactoryGirl.create(:section, :with_tags)).to be_valid
  end
  it 'is invalid without a title' do
    section = FactoryGirl.build(:section, title: nil)
    expect(section).to be_invalid
  end
  it 'is invalid without a number' do
    section = FactoryGirl.build(:section, number: nil)
    expect(section).to be_invalid
  end
  it 'is invalid with duplicate chapter and number' do
    chapter = FactoryGirl.build(:chapter)
    FactoryGirl.create(:section, chapter: chapter, number: 42)
    duplicate_section = FactoryGirl.build(:section, chapter: chapter,
                                                    number: 42)
    expect(duplicate_section).to be_invalid
  end
  it 'is invalid if number is not an integer' do
    section = FactoryGirl.build(:section, number: 'hello')
    expect(section).to be_invalid
  end
  it 'is invalid if number is lower than 0' do
    section = FactoryGirl.build(:section, number: -1)
    expect(section).to be_invalid
  end
  it 'is invalid if number is higher than 999' do
    section = FactoryGirl.build(:section, number: 1000)
    expect(section).to be_invalid
  end
end
