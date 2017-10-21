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
    FactoryGirl.create(:tag, title: 'usual BS')
    tag = FactoryGirl.build(:tag, title: 'usual BS')
    expect(tag).to be_invalid
  end
  describe 'graph theoretical methods' do
    before(:all) do
      @tags = FactoryGirl.create_list(:tag, 10)
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
    # context '.shortest_distance' do
    #   it 'returns the correct_distance two between_tags' do
    #     expect(Tag.shortest_distance(@tags[0], @tags[1])).to eq 1
    #     expect(Tag.shortest_distance(@tags[0], @tags[3])).to eq 2
    #     expect(Tag.shortest_distance(@tags[0], @tags[4])).to eq 3
    #     expect(Tag.shortest_distance(@tags[0], @tags[5])).to eq 3
    #     expect(Tag.shortest_distance(@tags[0], @tags[6])).to eq 2
    #     expect(Tag.shortest_distance(@tags[0], @tags[7])).to be_nil
    #     expect(Tag.shortest_distance(@tags[0], @tags[8])).to be_nil
    #     expect(Tag.shortest_distance(@tags[0], @tags[9])).to be_nil
    #     expect(Tag.shortest_distance(@tags[1], @tags[0])).to eq 1
    #     expect(Tag.shortest_distance(@tags[1], @tags[5])).to eq 2
    #     expect(Tag.shortest_distance(@tags[1], @tags[6])).to eq 1
    #     expect(Tag.shortest_distance(@tags[1], @tags[7])).to be_nil
    #     expect(Tag.shortest_distance(@tags[2], @tags[1])).to eq 2
    #     expect(Tag.shortest_distance(@tags[2], @tags[4])).to eq 4
    #     expect(Tag.shortest_distance(@tags[3], @tags[4])).to eq 1
    #     expect(Tag.shortest_distance(@tags[3], @tags[5])).to eq 1
    #     expect(Tag.shortest_distance(@tags[4], @tags[6])).to eq 1
    #     expect(Tag.shortest_distance(@tags[4], @tags[7])).to be_nil
    #     expect(Tag.shortest_distance(@tags[7], @tags[8])).to eq 1
    #     expect(Tag.shortest_distance(@tags[8], @tags[7])).to eq 1
    #     expect(Tag.shortest_distance(@tags[8], @tags[9])).to be_nil
    #   end
    # end
    # context '.shortest distances' do
    #   it 'returns the correct list of distances for one tag' do
    #     expect(Tag.shortest_distances(@tags[0]))
    #       .to include(@tags[0] => 0, @tags[1] => 1, @tags[2] => 1,
    #                   @tags[3] => 2, @tags[4] => 3, @tags[5] => 3,
    #                   @tags[6] => 2, @tags[7] => nil, @tags[8] => nil,
    #                   @tags[9] => nil)
    #     expect(Tag.shortest_distances(@tags[1]))
    #       .to include(@tags[0] => 1, @tags[1] => 0, @tags[2] => 2,
    #                   @tags[3] => 1, @tags[4] => 2, @tags[5] => 2,
    #                   @tags[6] => 1, @tags[7] => nil, @tags[8] => nil,
    #                   @tags[9] => nil)
    #     expect(Tag.shortest_distances(@tags[5]))
    #       .to include(@tags[0] => 3, @tags[1] => 2, @tags[2] => 4,
    #                   @tags[3] => 1, @tags[4] => 1, @tags[5] => 0,
    #                   @tags[6] => 2, @tags[7] => nil, @tags[8] => nil,
    #                   @tags[9] => nil)
    #     expect(Tag.shortest_distances(@tags[7]))
    #       .to include(@tags[0] => nil, @tags[1] => nil, @tags[2] => nil,
    #                   @tags[3] => nil, @tags[4] => nil, @tags[5] => nil,
    #                   @tags[6] => nil, @tags[7] => 0, @tags[8] => 1,
    #                   @tags[9] => nil)
    #   end
    # end
  end
end
