# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MampfSet, type: :model do
  it 'has a factory' do
    expect(FactoryBot.build(:mampf_set)).to be_kind_of(MampfSet)
  end
end
