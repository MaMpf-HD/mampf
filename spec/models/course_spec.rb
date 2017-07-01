require 'rails_helper'

RSpec.describe Course, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:course)).to be_valid
  end
  it 'has a valid factory for including tags' do
    expect(FactoryGirl.build(:course, :with_tags)).to be_valid
  end
  it 'is invalid without a title' do
    course = FactoryGirl.build(:course, title: nil)
    expect(course).to be_invalid
  end
  it 'is invalid with a duplicate title' do
    FactoryGirl.create(:course, title: 'usual bs')
    course = FactoryGirl.build(:course, title: 'usual bs')
    expect(course).to be_invalid
  end
end
