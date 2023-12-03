# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TimeStamp, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:time_stamp)).to be_valid
  end

  # test subfactories

  describe 'by string' do
    it 'has a valid factory' do
      time_stamp = FactoryBot.build(:time_stamp_by_string,
                                    time_string: '1:17:29.745')
      expect(time_stamp).to be_valid
    end
  end

  describe 'by hms' do
    it 'has a valid factory' do
      time_stamp = FactoryBot.build(:time_stamp_by_hms,
                                    h: 1, m: 17, s: 29, ms: 745)
      expect(time_stamp).to be_valid
    end
  end
end
