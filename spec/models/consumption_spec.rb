# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Consumption, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:consumption)).to be_valid
  end

  # describe traits

  describe 'with stuff' do
    before :all do
      @consumption = FactoryBot.build(:consumption, :with_stuff)
    end
    it 'has a medium id' do
      expect(@consumption.medium_id).to be_kind_of(Integer)
    end
    it 'has a sort' do
      expect(@consumption.sort).to be_truthy
    end
    it 'has a mode' do
      expect(@consumption.mode).to be_truthy
    end
    it 'has the correct mode for videos' do
      consumption = FactoryBot.build(:consumption, :with_stuff, sort: 'video')
      expect(consumption.mode.in?(['thyme', 'download'])).to be true
    end
    it 'has the correct mode for manuscripts' do
      consumption = FactoryBot.build(:consumption, :with_stuff,
                                     sort: 'manuscript')
      expect(consumption.mode.in?(['pdf_view', 'download'])).to be true
    end
  end
end
