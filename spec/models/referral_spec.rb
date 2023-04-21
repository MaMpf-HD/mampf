# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Referral, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:referral)).to be_valid
  end

  # test validations - INCOMPLETE

  it 'is invalid without an item' do
    expect(FactoryBot.build(:referral, item: nil)).to be_invalid
  end

  it 'is invalid without a medium' do
    expect(FactoryBot.build(:referral, medium: nil)).to be_invalid
  end

  # test traits and subfactories

  describe 'with times' do
    before :all do
      @referral = FactoryBot.build(:referral, :with_times)
    end
    it 'has a valid factory' do
      expect(@referral).to be_valid
    end
    it 'has a start time' do
      expect(@referral.start_time).to be_kind_of(TimeStamp)
    end
    it 'has an end time' do
      expect(@referral.end_time).to be_kind_of(TimeStamp)
    end
  end

  describe 'referral for sample video' do
    it 'has a valid factory' do
      expect(FactoryBot.build(:referral_for_sample_video)).to be_valid
    end
  end
end
