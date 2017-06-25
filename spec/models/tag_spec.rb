require 'rails_helper'

RSpec.describe Tag, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:tag)).to be_valid
  end
  it 'is invalid without a title' do
    tag = FactoryGirl.build(:tag, title: nil)
    expect(tag).to be_invalid
  end
  it 'is invalid with a duplicate title' do
    FactoryGirl.create(:tag, title: 'usual bs')
    tag = FactoryGirl.build(:tag, title: 'usual bs')
    expect(tag).to be_invalid
  end
end
