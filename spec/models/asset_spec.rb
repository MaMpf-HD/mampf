require 'rails_helper'

RSpec.describe Asset, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:asset)).to be_valid
  end
  it 'is invalid without a sort' do
    asset = FactoryGirl.build(:asset, sort: nil)
    expect(asset).to be_invalid
  end
  it 'is invalid with improper sort' do
    asset = FactoryGirl.build(:asset, sort: 'Test')
    expect(asset).to be_invalid
  end
  it 'is invalid without a title' do
    asset = FactoryGirl.build(:asset, title: nil)
    expect(asset).to be_invalid
  end
  it 'is invalid with a duplicate title' do
    FactoryGirl.create(:asset, title: 'usual bs')
    asset = FactoryGirl.build(:asset, title: 'usual bs')
    expect(asset).to be_invalid
  end
  context 'KeksQuiz' do
    it 'is invalid without a question_list' do
      asset = FactoryGirl.build(:asset, sort: 'KeksQuiz', question_list: nil)
      expect(asset).to be_invalid
    end
    it 'is invalid with improper question_list' do
      asset = FactoryGirl.build(:asset, sort: 'KeksQuiz',
                                        question_list: 'Hallo')
      expect(asset).to be_invalid
    end
    it 'is valid with proper question_list' do
      asset = FactoryGirl.build(:asset, sort: 'KeksQuiz',
                                        question_list: '25&30')
      expect(asset).to be_valid
    end
  end
  describe '#neighbours' do
    it 'returns the correct list of neighbours' do
      assets = FactoryGirl.create_list(:asset, 3)
      assets[0].linked_assets << [assets[1]]
      assets[2].linked_assets << [assets[1]]
      expect(assets[1].neighbours).to match_array([assets[0], assets[2]])
    end
  end
end
