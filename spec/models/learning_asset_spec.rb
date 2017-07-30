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
    learning_asset = FactoryGirl.build(:learning_asset, title: 'usual bs')
    expect(learning_asset).to be_invalid
  end
  context 'KeksQuizAsset' do
    it 'is invalid without a question_list' do
      learning_asset = FactoryGirl.build(:learning_asset, type: 'KeksQuizAsset',
                                                          question_list: nil)
      expect(learning_asset).to be_invalid
    end
    it 'is invalid with improper question_list' do
      learning_asset = FactoryGirl.build(:learning_asset, type: 'KeksQuizAsset',
                                                          question_list:
                                                            'Hallo')
      expect(learning_asset).to be_invalid
    end
    it 'is valid with proper question_list' do
      learning_asset = FactoryGirl.build(:learning_asset, type: 'KeksQuizAsset',
                                                          question_list:
                                                            '25&30')
      expect(learning_asset).to be_valid
    end
  end
  describe '#neighbours' do
    it 'returns the correct list of neighbours' do
      assets = FactoryGirl.create_list(:learning_asset,3)
      assets[0].linked_assets << [assets[1]]
      assets[2].linked_assets << [assets[1]]
      expect(assets[1].neighbours).to match_array([assets[0], assets[2]])
    end
  end
end
