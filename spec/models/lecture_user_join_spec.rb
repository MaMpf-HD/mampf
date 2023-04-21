# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LectureUserJoin, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:lecture_user_join)).to be_valid
  end

  # test validations

  it 'is invalid without a lecture' do
    expect(FactoryBot.build(:lecture_user_join, lecture: nil)).to be_invalid
  end

  it 'is invalid without a user' do
    expect(FactoryBot.build(:lecture_user_join, user: nil)).to be_invalid
  end
end
