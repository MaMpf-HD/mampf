# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reader, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:reader)).to be_valid
  end

  # test validations

  it 'is invalid without a user' do
    expect(FactoryBot.build(:reader, user: nil)).to be_invalid
  end

  it 'is invalid without a thread' do
    expect(FactoryBot.build(:reader, thread: nil)).to be_invalid
  end
end
