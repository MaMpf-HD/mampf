require 'rails_helper'

RSpec.describe Section, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:section)).to be_valid
  end
  it 'has a valid factory for including lessons' do
    expect(FactoryBot.create(:section, :with_lessons)).to be_valid
  end
  it 'has a valid factory for including tags' do
    expect(FactoryBot.create(:section, :with_tags)).to be_valid
  end
  it 'is invalid without a title' do
    section = FactoryBot.build(:section, title: nil)
    expect(section).to be_invalid
  end
  it 'is invalid without a number' do
    section = FactoryBot.build(:section, number: nil)
    expect(section).to be_invalid
  end
  it 'is invalid with duplicate chapter and number' do
    chapter = FactoryBot.build(:chapter)
    FactoryBot.create(:section, chapter: chapter, number: 42)
    duplicate_section = FactoryBot.build(:section, chapter: chapter,
                                                    number: 42)
    expect(duplicate_section).to be_invalid
  end
  it 'is invalid if number is not an integer' do
    section = FactoryBot.build(:section, number: 'hello')
    expect(section).to be_invalid
  end
  it 'is invalid if number is lower than 0' do
    section = FactoryBot.build(:section, number: -1)
    expect(section).to be_invalid
  end
  it 'is invalid if number is higher than 999' do
    section = FactoryBot.build(:section, number: 1000)
    expect(section).to be_invalid
  end
  it 'is invalid if lecture for lessons and chapter does not match' do
    first_lecture = FactoryBot.create(:lecture)
    second_lecture = FactoryBot.create(:lecture)
    lesson = FactoryBot.create(:lesson, lecture: first_lecture)
    chapter = FactoryBot.create(:chapter, lecture: second_lecture)
    section = FactoryBot.build(:section, chapter: chapter, lessons: [lesson])
    expect(section).to be_invalid
  end
  it 'is invalid if tags do nor belong to lecture' do
    lecture = FactoryBot.create(:lecture)
    chapter = FactoryBot.create(:chapter, lecture: lecture)
    tag = FactoryBot.create(:tag, :with_courses)
    section = FactoryBot.build(:section, chapter: chapter, tags: [tag])
    expect(section).to be_invalid
  end
  describe '#chapter' do
    it 'returns the correct chapter' do
      chapter = FactoryBot.create(:chapter)
      section = FactoryBot.build(:section, chapter: chapter)
      expect(section.chapter).to eq(chapter)
    end
  end
  describe '#to_label' do
    it 'returns the correct label' do
      section = FactoryBot.create(:section, number: 7, title: 'Star Wars')
      expect(section.to_label).to eq('§7. Star Wars')
    end
    it 'returns the correct label if number_alt is given' do
      section = FactoryBot.create(:section, number: 7, number_alt: '5.2',
                                            title: 'Star Wars')
      expect(section.to_label).to eq('§5.2. Star Wars')
    end
  end
end
