# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Chapter, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:chapter)).to be_valid
  end

  # test validations

  it 'is invalid without a title' do
    chapter = FactoryBot.build(:chapter, title: nil)
    expect(chapter).to be_invalid
  end

  # test traits

  describe 'chapter with sections' do
    before :all do
      @chapter = FactoryBot.build(:chapter, :with_sections)
    end
    it 'has a valid factory' do
      expect(@chapter).to be_valid
    end
    it 'has 3 sections when called without section_count parameter' do
      expect(@chapter.sections.size).to eq 3
    end
    it 'has the correct number of sections' do
      chapter = FactoryBot.build(:chapter, :with_sections, section_count: 5)
      expect(chapter.sections.size).to eq 5
    end
  end

  # test methods - NEEDS TO BE REFACTORED

  # describe '#to_label' do
  #   it 'returns the correct label' do
  #     chapter = FactoryBot.create(:chapter, title: 'Star Wars')
  #     expect(chapter.to_label).to eq('Kapitel 1. Star Wars')
  #   end
  # end

  # describe '#tags' do
  #   it 'returns the correct tags' do
  #     chapter = FactoryBot.create(:chapter)
  #     first_section = FactoryBot.create(:section, :with_tags)
  #     second_section = FactoryBot.create(:section, :with_tags)
  #     chapter.sections << [first_section,second_section]
  #     tags = first_section.tags + second_section.tags
  #     expect(chapter.tags.to_a).to match_array(tags)
  #   end
  # end

  # describe '#lessons' do
  #   it 'returns the correct lessons' do
  #     chapter = FactoryBot.create(:chapter)
  #     first_section = FactoryBot.create(:section, :with_lessons)
  #     second_section = FactoryBot.create(:section, :with_lessons)
  #     chapter.sections << [first_section,second_section]
  #     lessons = first_section.lessons + second_section.lessons
  #     expect(chapter.lessons.to_a).to match_array(lessons)
  #   end
  # end
end
