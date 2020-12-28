# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Division, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:division)).to be_valid
  end

  # test validations

  it 'is invalid without a program' do
    expect(FactoryBot.build(:division, program: nil)).to be_invalid
  end
end
