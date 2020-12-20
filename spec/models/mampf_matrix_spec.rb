require 'rails_helper'

RSpec.describe MampfMatrix, type: :model do
  it 'has a factory' do
    expect(FactoryBot.build(:mampf_matrix)
      .is_a?(MampfMatrix)).to be true
  end
end