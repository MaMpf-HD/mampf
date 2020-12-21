require 'rails_helper'

RSpec.describe Submission, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:valid_submission)).to be_valid
  end
end
