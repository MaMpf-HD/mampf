require 'rails_helper'

RSpec.describe Item, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:item)).to be_valid
  end

  # test validations - SOME ARE MISSING

  it 'is invalid with inadmissible sort' do
    expect(FactoryBot.build(:item, sort: 'some BS')).to be_invalid
  end

  # test traits

  describe 'with start time' do
    it 'has a start time' do
      item = FactoryBot.build(:item, :with_start_time)
      expect(item.start_time.is_a?(TimeStamp)).to be true
    end
  end

  describe 'with medium' do
    it 'has a medium' do
      item = FactoryBot.build(:item, :with_medium)
      expect(item.medium.is_a?(Medium)).to be true
    end
  end
end