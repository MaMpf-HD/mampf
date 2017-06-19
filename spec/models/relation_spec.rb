require 'rails_helper'

RSpec.describe Relation, type: :model do
  it "has a valid factory" do
    expect(FactoryGirl.build(:relation)).to be_valid
  end
end
