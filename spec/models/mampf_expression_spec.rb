# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MampfExpression, type: :model do
  it 'has a factory' do
    expect(FactoryBot.build(:mampf_expression)).to be_kind_of(MampfExpression)
  end
end
