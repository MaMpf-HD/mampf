# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Solution, type: :model do
  it 'has a factory' do
    expect(FactoryBot.build(:solution)).to be_kind_of(Solution)
  end
end
