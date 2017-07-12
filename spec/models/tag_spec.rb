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
  describe '#neighbours' do
    it 'returns a correct list of neighbours' do
      tags = FactoryGirl.create_list(:tag, 5)
      tags[0].related_tags << [tags[1], tags[2]]
      tags[1].related_tags << [tags[3]]
      expect(tags[0].neighbours).to match_array([tags[1], tags[2]])
      expect(tags[1].neighbours).to match_array([tags[0], tags[3]])
      expect(tags[2].neighbours).to match_array([tags[0]])
      expect(tags[3].neighbours).to match_array([tags[1]])
      expect(tags[4].neighbours).to match_array([])
    end
  end
end
