# frozen_string_literal: true

require 'rails_helper'

RSpec.describe QuizGraph, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:quiz_graph)).to be_valid
  end

  # test traits and subfactories

  describe 'linear graph' do
    before :all do
      @graph = FactoryBot.build(:quiz_graph, :linear)
    end
    it 'does not contain errors' do
      expect(@graph.find_errors).to eq []
    end
    it 'has 3 questions when called without question_count parameter' do
      expect(@graph.vertices.keys).to eq [1, 2, 3]
    end
    it 'has no nontrivial edges' do
      expect(@graph.edges).to eq({})
    end
    it 'has 1 as root' do
      expect(@graph.root).to eq 1
    end
    it 'has a linear default table' do
      expect(@graph.default_table).to eq({ 1 => 2, 2 => 3, 3 => -1 })
    end
  end

  # test methods - NEEDS TO BE IMPLEMENTED
end
