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
  describe '#to_label' do
    it 'returns the correct label' do
      chapter = FactoryBot.create(:chapter, number: 5, title: 'Star Wars')
      expect(chapter.to_label).to eq('Kapitel 5. Star Wars')
    end
  end
  describe '#tags' do
    it 'returns the correct tags' do
      chapter = FactoryBot.create(:chapter)
      first_section = FactoryBot.create(:section, :with_tags)
      second_section = FactoryBot.create(:section, :with_tags)
      chapter.sections << [first_section,second_section]
      tags = first_section.tags + second_section.tags
      expect(chapter.tags.to_a).to match_array(tags)
    end
  end
  describe '#lessons' do
    it 'returns the correct lessons' do
      chapter = FactoryBot.create(:chapter)
      first_section = FactoryBot.create(:section, :with_lessons)
      second_section = FactoryBot.create(:section, :with_lessons)
      chapter.sections << [first_section,second_section]
      lessons = first_section.lessons + second_section.lessons
      expect(chapter.lessons.to_a).to match_array(lessons)
    end
  end
end
