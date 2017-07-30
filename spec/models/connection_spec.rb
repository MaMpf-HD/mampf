require 'rails_helper'

RSpec.describe Connection, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:connection)).to be_valid
  end
  it 'is invalid without learning_asset' do
    connection = FactoryGirl.build(:connection, learning_asset: nil)
    expect(connection).to be_invalid
  end
  it 'is invalid without linked_asset' do
    connection = FactoryGirl.build(:connection, linked_asset: nil)
    expect(connection).to be_invalid
  end
  it 'is invalid if connection already exists' do
    learning_asset = FactoryGirl.create(:learning_asset)
    linked_asset = FactoryGirl.create(:linked_asset)
    FactoryGirl.create(:connection, learning_asset: learning_asset,
                                    linked_asset: linked_asset)
    duplicate_connection = FactoryGirl.build(:connection,
                                                learning_asset: learning_asset,
                                                linked_asset: linked_asset)
    expect(duplicate_connection).to be_invalid
  end
  it 'is invalid if it links learning_asset to itself' do
    learning_asset = FactoryGirl.create(:learning_asset)
    connection = FactoryGirl.build(:connection, learning_asset: learning_asset,
                                                linked_asset: learning_asset)
    expect(connection).to be_invalid
  end
end
