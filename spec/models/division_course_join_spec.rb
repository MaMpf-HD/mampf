# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DivisionCourseJoin, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:division_course_join)).to be_valid
  end

  # test validations

  it 'is invalid without a course' do
    expect(FactoryBot.build(:division_course_join, course: nil)).to be_invalid
  end

  it 'is invalid without a division' do
    expect(FactoryBot.build(:division_course_join, division: nil)).to be_invalid
  end
end
