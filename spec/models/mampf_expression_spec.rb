require 'rails_helper'

RSpec.describe MampfExpression, type: :model do
  it 'has a factory' do
    expect(FactoryBot.build(:mampf_expression)
      .is_a?(MampfExpression)).to be true
  end
end