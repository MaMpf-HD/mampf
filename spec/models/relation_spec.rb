require 'rails_helper'

RSpec.describe Relation, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:relation)).to be_valid
  end
  it 'is invalid without tag' do
    relation = FactoryGirl.build(:relation, tag: nil)
    expect(relation).to be_invalid
  end
  it 'is invalid without related_tag' do
    relation = FactoryGirl.build(:relation, related_tag: nil)
    expect(relation).to be_invalid
  end
  it 'is invalid if relation already exists' do
    tag = FactoryGirl.create(:tag)
    related_tag = FactoryGirl.create(:tag)
    FactoryGirl.create(:relation, tag: tag, related_tag: related_tag)
    duplicate_relation = FactoryGirl.build(:relation, tag: tag,
                                                      related_tag: related_tag)
    expect(duplicate_relation).to be_invalid
  end
  it 'is invalid if inverse relation already exists' do
    tag = FactoryGirl.create(:tag)
    related_tag = FactoryGirl.create(:tag)
    FactoryGirl.create(:relation, tag: tag, related_tag: related_tag)
    inverse_relation = FactoryGirl.build(:relation, tag: related_tag,
                                                    related_tag: tag)
    expect(inverse_relation).to be_invalid
  end
end
