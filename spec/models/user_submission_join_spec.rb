# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserSubmissionJoin, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:user_submission_join)).to be_valid
  end

  # test validations - INCOMPLETE

  it 'is invalid without a user' do
    expect(FactoryBot.build(:user_submission_join, user: nil)).to be_invalid
  end
end
