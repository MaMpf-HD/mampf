require 'rails_helper'

RSpec.describe Tag, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:tag)).to be_valid
  end
  it 'is invalid without a title' do
    tag = FactoryBot.build(:tag, title: nil)
    expect(tag).to be_invalid
  end
  it 'is invalid with a duplicate title' do
    FactoryBot.create(:tag, title: 'usual BS')
    tag = FactoryBot.build(:tag, title: 'usual BS')
    expect(tag).to be_invalid
  end
  describe 'graph theoretical methods' do
    before(:all) do
      @tags = FactoryBot.create_list(:tag, 10)
      @tags[0].related_tags << [@tags[1], @tags[2]]
      @tags[1].related_tags << [@tags[3], @tags[6]]
      @tags[3].related_tags << [@tags[4], @tags[5]]
      @tags[4].related_tags << [@tags[5], @tags[6]]
      @tags[7].related_tags << [@tags[8]]
    end
    context '#related_tags' do
      it 'returns the correct list of related_tags' do
        expect(@tags[0].related_tags).to match_array([@tags[1], @tags[2]])
        expect(@tags[1].related_tags).to match_array([@tags[0], @tags[3],
                                                    @tags[6]])
        expect(@tags[2].related_tags).to match_array([@tags[0]])
        expect(@tags[3].related_tags).to match_array([@tags[1], @tags[4],
                                                    @tags[5]])
        expect(@tags[4].related_tags).to match_array([@tags[3], @tags[5],
                                                    @tags[6]])
        expect(@tags[5].related_tags).to match_array([@tags[3], @tags[4]])
        expect(@tags[6].related_tags).to match_array([@tags[1], @tags[4]])
        expect(@tags[7].related_tags).to match_array([@tags[8]])
        expect(@tags[8].related_tags).to match_array([@tags[7]])
        expect(@tags[9].related_tags).to match_array([])
      end
    end
  end
end
