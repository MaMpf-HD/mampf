require 'rails_helper'

RSpec.describe LearningAsset, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:learning_asset)).to be_valid
  end
  it 'is invalid without a description' do
    learning_asset = FactoryGirl.build(:learning_asset, description: nil)
    expect(learning_asset).to be_invalid
  end
end
