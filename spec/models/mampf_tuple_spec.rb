require 'rails_helper'

RSpec.describe MampfTuple, type: :model do
  it 'has a factory' do
    expect(FactoryBot.build(:mampf_tuple)
      .is_a?(MampfTuple)).to be true
  end
end