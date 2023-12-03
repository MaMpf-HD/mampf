# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Answer, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:valid_answer)).to be_valid
  end

  # test validations
  it 'is invalid without a question' do
    answer = FactoryBot.build(:valid_answer)
    answer.question = nil
    expect(answer).to be_invalid
  end

  # test traits

  describe 'with stuff' do
    before :all do
      @answer = FactoryBot.build(:answer, :with_stuff)
    end
    it 'has a text' do
      expect(@answer.text).to be_truthy
    end
    it 'has a value' do
      expect(@answer.value).to be_in([true, false])
    end
    it 'has an explanation' do
      expect(@answer.explanation).to be_truthy
    end
  end

  # test methods - NEEDS TO BE IMPLEMENTED
end
