# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Subject, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:subject)).to be_valid
  end
end
