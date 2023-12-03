# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LessonTagJoin, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:lesson_tag_join)).to be_valid
  end

  # test validations

  it 'is invalid without a lesson' do
    expect(FactoryBot.build(:lesson_tag_join, lesson: nil)).to be_invalid
  end

  it 'is invalid without a tag' do
    expect(FactoryBot.build(:lesson_tag_join, tag: nil)).to be_invalid
  end
end
