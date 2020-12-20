require 'rails_helper'

RSpec.describe Manuscript, type: :model do
  it 'has a factory' do
    expect(FactoryBot.build(:manuscript).is_a?(Manuscript)).to be true
  end
end