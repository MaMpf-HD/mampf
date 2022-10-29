# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Manuscript, type: :model do
  it 'has a factory' do
    expect(FactoryBot.build(:manuscript)).to be_kind_of(Manuscript)
  end
end
