require 'rails_helper'

RSpec.describe Connection, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:connection)).to be_valid
  end
  it 'is invalid without asset' do
    connection = FactoryGirl.build(:connection, asset: nil)
    expect(connection).to be_invalid
  end
  it 'is invalid without linked_asset' do
    connection = FactoryGirl.build(:connection, linked_asset: nil)
    expect(connection).to be_invalid
  end
  it 'is invalid if connection already exists' do
    asset = FactoryGirl.create(:asset)
    linked_asset = FactoryGirl.create(:linked_asset)
    FactoryGirl.create(:connection, asset: asset,
                                    linked_asset: linked_asset)
    duplicate_connection = FactoryGirl.build(:connection,
                                                asset: asset,
                                                linked_asset: linked_asset)
    expect(duplicate_connection).to be_invalid
  end
  it 'is invalid if it links asset to itself' do
    asset = FactoryGirl.create(:asset)
    connection = FactoryGirl.build(:connection, asset: asset,
                                                linked_asset: asset)
    expect(connection).to be_invalid
  end
end
