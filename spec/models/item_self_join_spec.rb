# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ItemSelfJoin, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:item_self_join)).to be_valid
  end

  # test validations

  it 'is invalid without an item' do
    expect(FactoryBot.build(:item_self_join, item: nil)).to be_invalid
  end

  it 'is invalid without a related item' do
    expect(FactoryBot.build(:item_self_join, related_item: nil)).to be_invalid
  end

  it 'is invalid with a duplicate related_item' do
    item_join = FactoryBot.create(:item_self_join)
    item = item_join.item
    related_item = item_join.related_item
    new_join = FactoryBot.build(:item_self_join,
                                item: item,
                                related_item: related_item)
    expect(new_join).to be_invalid
  end
end
