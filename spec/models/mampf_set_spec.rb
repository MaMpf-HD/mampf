require 'rails_helper'

RSpec.describe MampfSet, type: :model do
  it 'has a factory' do
    expect(FactoryBot.build(:mampf_set)
      .is_a?(MampfSet)).to be true
  end
end