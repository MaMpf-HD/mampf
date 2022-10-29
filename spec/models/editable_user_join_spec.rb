# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EditableUserJoin, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:editable_user_join)).to be_valid
  end

  # test validations

  it 'is invalid without an editable' do
    expect(FactoryBot.build(:editable_user_join, editable: nil)).to be_invalid
  end

  it 'is invalid without a user' do
    expect(FactoryBot.build(:editable_user_join, user: nil)).to be_invalid
  end

  # test traits

  describe 'with course' do
    it 'is associated to a course' do
      course_join = FactoryBot.build(:editable_user_join, :with_course)
      expect(course_join.editable).to be_kind_of(Course)
    end
  end

  describe 'with lecture' do
    it 'is associated to a lecture' do
      lecture_join = FactoryBot.build(:editable_user_join, :with_lecture)
      expect(lecture_join.editable).to be_kind_of(Lecture)
    end
  end
end
