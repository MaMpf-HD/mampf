# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Question, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:valid_question)).to be_valid
  end

  # test validations - this is done one the level of the parent Medium model

  # test traits

  describe 'with stuff' do
    before :all do
      @question = FactoryBot.build(:question, :with_stuff)
    end
    it 'has a text' do
      expect(@question.text).to be_truthy
    end
    it 'has a hint' do
      expect(@question.hint).to be_truthy
    end
    it 'has a level' do
      expect(@question.level).to be_kind_of(Integer)
    end
    it 'is a multiple choice question' do
      expect(@question.question_sort).to eq 'mc'
    end
    it 'is independent' do
      expect(@question.independent).to be true
    end
  end

  describe 'with answers' do
    it 'has 3 answers' do
      question = FactoryBot.build(:valid_question, :with_answers)
      expect(question.answers.size).to eq 3
    end
    it 'has the correct amount of answers with answers_count param' do
      question = FactoryBot.build(:valid_question, :with_answers,
                                  answers_count: 4)
      expect(question.answers.size).to eq 4
    end
  end

  # test methods - NEEDS TO BE IMPLEMENTED
end
