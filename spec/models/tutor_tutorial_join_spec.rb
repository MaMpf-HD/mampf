# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TutorTutorialJoin, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:tutor_tutorial_join)).to be_valid
  end

  # test validations

  it 'is invalid without a tutor' do
    expect(FactoryBot.build(:tutor_tutorial_join, tutor: nil)).to be_invalid
  end

  it 'is invalid without a tutorial' do
    expect(FactoryBot.build(:tutor_tutorial_join, tutorial: nil)).to be_invalid
  end
end
