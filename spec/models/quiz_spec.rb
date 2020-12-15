require 'rails_helper'

RSpec.describe Quiz, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:valid_quiz)).to be_valid
  end

  # test validations - this is done one the level of the parent Medium model

  # test traits and subfactories

  describe 'random quiz' do
    it 'has a valid factory' do
      expect(FactoryBot.build(:valid_random_quiz)).to be_valid
    end
  end

  # test methods - NEEDS TO BE IMPLEMENTED
end
