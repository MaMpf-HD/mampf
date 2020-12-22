# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Relation, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:relation)).to be_valid
  end

  # test validations

  it 'is invalid without tag' do
    relation = FactoryBot.build(:relation, tag: nil)
    expect(relation).to be_invalid
  end

  it 'is invalid without related_tag' do
    relation = FactoryBot.build(:relation, related_tag: nil)
    expect(relation).to be_invalid
  end

  it 'is invalid if relation already exists' do
    tag = FactoryBot.create(:tag)
    related_tag = FactoryBot.create(:tag)
    FactoryBot.create(:relation, tag: tag, related_tag: related_tag)
    duplicate_relation = FactoryBot.build(:relation, tag: tag,
                                                     related_tag: related_tag)
    expect(duplicate_relation).to be_invalid
  end

  # test callbacks

  it 'destroys itself if it relates tag to itself' do
    tag = FactoryBot.create(:tag)
    relation = FactoryBot.create(:relation, tag: tag, related_tag: tag)
    expect(Relation.find_by_id(relation.id)).to be_nil
  end

  it 'creates an inverse if relation is not self-inverse' do
    first_tag = FactoryBot.create(:tag)
    second_tag = FactoryBot.create(:tag)
    FactoryBot.create(:relation, tag: first_tag, related_tag: second_tag)
    expect(Relation.exists?(tag: second_tag, related_tag: first_tag)).to be true
  end

  it 'destroys the inverse after deletion if relation is not self-inverse' do
    first_tag = FactoryBot.create(:tag)
    second_tag = FactoryBot.create(:tag)
    relation = FactoryBot.create(:relation, tag: first_tag,
                                            related_tag: second_tag)
    relation.destroy
    expect(Relation.exists?(tag: second_tag, related_tag: first_tag))
      .to be false
  end
end
