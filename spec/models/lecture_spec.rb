require 'rails_helper'

RSpec.describe Lecture, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:lecture)).to be_valid
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
end
