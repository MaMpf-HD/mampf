# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LessonSectionJoin, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:lesson_section_join)).to be_valid
  end

  # test validations

  it 'is invalid without a lesson' do
    expect(FactoryBot.build(:lesson_section_join, lesson: nil)).to be_invalid
  end

  it 'is invalid without a section' do
    expect(FactoryBot.build(:lesson_section_join, section: nil)).to be_invalid
  end
end
