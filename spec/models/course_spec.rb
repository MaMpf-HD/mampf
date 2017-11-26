require 'rails_helper'

RSpec.describe Course, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:course)).to be_valid
  end
  it 'has a valid factory for including tags' do
    expect(FactoryBot.build(:course, :with_tags)).to be_valid
  end
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
  describe '#to_label' do
    it 'returns the correct label' do
      course = FactoryBot.build(:course, title: 'usual bs')
      expect(course.to_label).to eq('usual bs')
    end
  end
  describe '#description' do
    it 'returns the correct description' do
      course = FactoryBot.build(:course, title: 'usual bs')
      expect(course.description).to eq({ general: 'usual bs' })
    end
  end
end
