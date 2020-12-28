# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MampfTuple, type: :model do
  it 'has a factory' do
    expect(FactoryBot.build(:mampf_tuple)).to be_kind_of(MampfTuple)
  end
end
