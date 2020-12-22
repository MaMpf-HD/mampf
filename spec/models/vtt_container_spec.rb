# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VttContainer, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:vtt_container)).to be_valid
  end
end
