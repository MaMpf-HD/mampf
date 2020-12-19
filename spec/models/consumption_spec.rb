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
      expect(@consumption.medium_id).not_to be_nil
    end
    it 'has a sort' do
      expect(@consumption.sort).to be_truthy
    end
    it 'has a mode' do
      expect(@consumption.mode).to be_truthy
    end
  end
end
