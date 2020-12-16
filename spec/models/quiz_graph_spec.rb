require 'rails_helper'

RSpec.describe QuizGraph, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:quiz_graph)).to be_valid
  end

  # test traits and subfactories

  # test methods - NEEDS TO BE IMPLEMENTED
end