# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QuizRound, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:quiz_round)).to be_valid
  end
end
