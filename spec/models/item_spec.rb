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

  # test traits and subfactories

  describe 'with start time' do
    it 'has a start time' do
      item = FactoryBot.build(:item, :with_start_time)
      expect(item.start_time).to be_kind_of(TimeStamp)
    end
    it 'has the correct start time when the starting_time param is used' do
      item = FactoryBot.build(:item, :with_start_time, starting_time: 1000)
      expect(item.start_time.total_seconds).to eq 1000
    end
  end

  describe 'with medium' do
    it 'has a medium' do
      item = FactoryBot.build(:item, :with_medium)
      expect(item.medium).to be_kind_of(Medium)
    end
    it 'has a medium with a video' do
      item = FactoryBot.build(:item, :with_medium)
      expect(item.medium.video).to be_kind_of(VideoUploader::UploadedFile)
    end
  end

  describe 'item for sample video' do
    it 'has a valid factory' do
      expect(FactoryBot.build(:item_for_sample_video)).to be_valid
    end
  end
end
