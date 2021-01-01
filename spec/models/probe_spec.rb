# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Probe, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:probe)).to be_valid
  end

  # describe traits

  describe 'with stuff' do
    before :all do
      @probe = FactoryBot.build(:probe, :with_stuff)
    end
    it 'has a question id' do
      expect(@probe.question_id).to be_kind_of(Integer)
    end
    it 'quiz_id' do
      expect(@probe.quiz_id).to be_kind_of(Integer)
    end
    it 'is correct or not' do
      expect(@probe.correct).to be_in([true, false])
    end
    it 'has a session id' do
      expect(@probe.session_id).to be_truthy
    end
    it 'has a progress' do
      expect(@probe.progress).to be_kind_of(Integer)
    end
    it 'has a success' do
      expect(@probe.success).to be_kind_of(Integer)
    end
    it 'has a success that is between 1 and 3 if progress is -1' do
      probe = FactoryBot.build(:probe, :with_stuff, progress: -1)
      expect(probe.success.in?([1, 2, 3])).to be true
    end
    it 'has a success that is between 1 and progress' do
      probe = FactoryBot.build(:probe, :with_stuff, progress: 10)
      expect(probe.success.in?((1..10).to_a)).to be true
    end
  end
end
