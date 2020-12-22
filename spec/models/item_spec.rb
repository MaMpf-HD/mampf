# frozen_string_literal: true

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
      expect(item.start_time).to be_kind_of(TimeStamp)
    end
  end

  describe 'with medium' do
    it 'has a medium' do
      item = FactoryBot.build(:item, :with_medium)
      expect(item.medium).to be_kind_of(Medium)
    end
  end
end
