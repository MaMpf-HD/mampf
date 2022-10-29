# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MampfMatrix, type: :model do
  it 'has a factory' do
    expect(FactoryBot.build(:mampf_matrix)).to be_kind_of(MampfMatrix)
  end
end
