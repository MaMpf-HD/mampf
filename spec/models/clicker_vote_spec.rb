# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClickerVote, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:valid_clicker_vote)).to be_valid
  end

  # test validations

  it 'is invalid if clicker is not open' do
    vote = FactoryBot.build(:valid_clicker_vote)
    vote.clicker.open = false
    expect(vote).to be_invalid
  end

  it 'is invalid if value is out of range' do
    vote = FactoryBot.build(:valid_clicker_vote, value: 5)
    expect(vote).to be_invalid
  end
end
