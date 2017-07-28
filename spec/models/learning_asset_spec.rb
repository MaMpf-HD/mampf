require 'rails_helper'

RSpec.describe LearningAsset, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:learning_asset)).to be_valid
  end
  it 'is invalid without a title' do
    learning_asset = FactoryGirl.build(:learning_asset, title: nil)
    expect(learning_asset).to be_invalid
  end
  it 'is invalid with a duplicate title' do
    FactoryGirl.create(:learning_asset, title: 'usual bs')
    medium = FactoryGirl.build(:learning_asset, title: 'usual bs')
    expect(medium).to be_invalid
  end
end
