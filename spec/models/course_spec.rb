# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Course, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:course)).to be_valid
  end

  # Test validations

  it 'is invalid without a title' do
    course = FactoryBot.build(:course, title: nil)
    expect(course).to be_invalid
  end
  it 'is invalid with a duplicate title' do
    FactoryBot.create(:course, title: 'usual bs')
    course = FactoryBot.build(:course, title: 'usual bs')
    expect(course).to be_invalid
  end
  it 'is invalid without a short title' do
    course = FactoryBot.build(:course, short_title: nil)
    expect(course).to be_invalid
  end
  it 'is invalid with a duplicate short title' do
    FactoryBot.create(:course, short_title: 'usual bs')
    course = FactoryBot.build(:course, short_title: 'usual bs')
    expect(course).to be_invalid
  end

  # Test traits

  describe 'course with tags' do
    before :all do
      @course = FactoryBot.build(:course, :with_tags)
    end
    it 'has a valid factory' do
      expect(@course).to be_valid
    end
    it 'has tags' do
      expect(@course.tags).not_to be_nil
    end
    it 'has 3 tags when called without tag_count parameter' do
      expect(@course.tags.size).to eq 3
    end
    it 'has correct number of tags when called with tag_count parameter' do
      course = FactoryBot.build(:course, :with_tags, tag_count: 5)
      expect(course.tags.size).to eq 5
    end
  end

  describe 'term independent course' do
    course = FactoryBot.build(:course, :term_independent)
    it 'has a valid factory' do
      expect(course).to be_valid
    end
    it 'is term independent' do
      expect(course.term_independent).to be true
    end
  end

  describe 'course with organizational stuff' do
    course = FactoryBot.build(:course, :with_organizational_stuff)
    it 'has a valid factory' do
      expect(course).to be_valid
    end
    it 'has organzational flag set to true' do
      expect(course.organizational).to be true
    end
    it 'has an organizational concept' do
      expect(course.organizational_concept).to be_truthy
    end
  end

  describe 'course with locale de' do
    course = FactoryBot.build(:course, :locale_de)
    it 'has a valid factory' do
      expect(course).to be_valid
    end
    it 'has locale de' do
      expect(course.locale).to eq 'de'
    end
  end

  # Test methods -- NEEDS TO BE REFACTORED

  # describe '#to_label' do
  #   it 'returns the correct label' do
  #     course = FactoryBot.build(:course, title: 'usual bs')
  #     expect(course.to_label).to eq('usual bs')
  #   end
  # end
end
