require 'rails_helper'

RSpec.describe Tag, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.create(:tag)).to be_valid
  end
  describe '#tags_in_neighbourhood' do
    it 'returns the correct list of related_tags' do
      @tags = FactoryBot.create_list(:tag, 10)
      @tags[0].related_tags << [@tags[1], @tags[2]]
      @tags[1].related_tags << [@tags[3], @tags[6]]
      @tags[3].related_tags << [@tags[4], @tags[5]]
      @tags[4].related_tags << [@tags[5], @tags[6]]
      @tags[7].related_tags << [@tags[8]]
      expect(@tags[0].tags_in_neighbourhood).to match_array([@tags[3], @tags[6]])
      expect(@tags[6].tags_in_neighbourhood).to match_array([@tags[0], @tags[3], @tags[5]])
      expect(@tags[7].tags_in_neighbourhood).to match_array([])
      expect(@tags[9].tags_in_neighbourhood).to match_array([])
    end
  end
  describe '#in_lecture?' do
    it 'returns true if the tag belongs to the lecture' do
      tag = FactoryBot.create(:tag)
      lecture = FactoryBot.create(:lecture, additional_tags: [tag])
      expect(tag.in_lecture?(lecture)).to be true
    end
    it 'returns false if the tag does not belong to the lecture' do
      tag = FactoryBot.create(:tag)
      lecture = FactoryBot.create(:lecture, disabled_tags: [tag])
      expect(tag.in_lecture?(lecture)).to be false
    end
  end
  describe '#in_lectures?' do
    it 'returns true if the tag belongs to the lectures' do
      tag = FactoryBot.create(:tag)
      first_lecture = FactoryBot.create(:lecture, additional_tags: [tag])
      second_lecture = FactoryBot.create(:lecture, disabled_tags: [tag])
      expect(tag.in_lectures?([first_lecture, second_lecture])).to be true
    end
    it 'returns false if the tag does not belong to the lectures' do
      tag = FactoryBot.create(:tag)
      first_lecture = FactoryBot.create(:lecture, disabled_tags: [tag])
      second_lecture = FactoryBot.create(:lecture, disabled_tags: [tag])
      expect(tag.in_lectures?([first_lecture, second_lecture])).to be false
    end
  end
  describe '#lectures' do
    it 'returns the correct list of lectures to which the tag is associated' do
      course = FactoryBot.create(:course)
      tag = FactoryBot.create(:tag)
      course.tags << tag
      first_lecture = FactoryBot.create(:lecture, course: course)
      second_lecture = FactoryBot.create(:lecture, additional_tags: [tag])
      third_lecture = FactoryBot.create(:lecture, disabled_tags: [tag])
      expect(tag.lectures.to_a).to match_array([first_lecture,second_lecture])
    end
  end
end
