require 'rails_helper'

RSpec.describe Lecture, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:lecture)).to be_valid
  end
  it 'has a valid factory for including tags' do
    expect(FactoryGirl.build(:lecture, :with_disabled_tags)).to be_valid
  end
  it 'is invalid without a term' do
    lecture = FactoryGirl.build(:lecture, term: nil)
    expect(lecture).to be_invalid
  end
  it 'is invalid without a teacher' do
    lecture = FactoryGirl.build(:lecture, teacher: nil)
    expect(lecture).to be_invalid
  end
  it 'is invalid without a course' do
    lecture = FactoryGirl.build(:lecture, course: nil)
    expect(lecture).to be_invalid
  end
  it 'is invalid if duplicate combination of course,teacher and term' do
    course = FactoryGirl.create(:course)
    teacher = FactoryGirl.create(:teacher)
    term = FactoryGirl.create(:term)
    FactoryGirl.create(:lecture, course: course, teacher: teacher, term: term)
    lecture = FactoryGirl.build(:lecture, course: course, teacher: teacher,
                                          term: term)
    expect(lecture).to be_invalid
  end
  describe '#tags' do
    it 'returns the correct tags for the lecture' do
      tags = create_list(:tag, 3)
      course = FactoryGirl.create(:course, tags: tags)
      additional_tags = create_list(:tag, 2)
      disabled_tags = [tags[0], tags[1]]
      lecture = FactoryGirl.create(:lecture, course: course,
                                             additional_tags: additional_tags,
                                             disabled_tags: disabled_tags)
      expect(lecture.tags).to match_array([tags[2], additional_tags[0],
                                           additional_tags[1]])
    end
  end
end
