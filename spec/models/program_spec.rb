# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Program, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:program)).to be_valid
  end

  # test validations

  it 'is invalid without a subject' do
    expect(FactoryBot.build(:program, subject: nil)).to be_invalid
  end
end
