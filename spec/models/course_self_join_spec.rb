# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CourseSelfJoin, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:course_self_join)).to be_valid
  end

  # test validations

  it 'is invalid without a course' do
    expect(FactoryBot.build(:course_self_join, course: nil)).to be_invalid
  end

  it 'is invalid without a preceding course' do
    expect(FactoryBot.build(:course_self_join, preceding_course: nil))
      .to be_invalid
  end

  it 'is invalid with a duplicate preceding course' do
    course_join = FactoryBot.create(:course_self_join)
    course = course_join.course
    preceding_course = course_join.preceding_course
    new_join = FactoryBot.build(:course_self_join,
                                course: course,
                                preceding_course: preceding_course)
    expect(new_join).to be_invalid
  end
end
