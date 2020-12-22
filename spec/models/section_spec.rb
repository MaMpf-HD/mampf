# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Section, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:section)).to be_valid
  end

  # test validations

  it 'is invalid without a title' do
    section = FactoryBot.build(:section, title: nil)
    expect(section).to be_invalid
  end

  # test methods - NEEDS TO BE REFACTORED

  # describe '#chapter' do
  #   it 'returns the correct chapter' do
  #     chapter = FactoryBot.create(:chapter)
  #     section = FactoryBot.build(:section, chapter: chapter)
  #     expect(section.chapter).to eq(chapter)
  #   end
  # end

  # describe '#to_label' do
  #   it 'returns the correct label' do
  #     section = FactoryBot.create(:section, number: 7, title: 'Star Wars')
  #     expect(section.to_label).to eq('§7. Star Wars')
  #   end
  #   it 'returns the correct label if number_alt is given' do
  #     section = FactoryBot.create(:section, number: 7, number_alt: '5.2',
  #                                           title: 'Star Wars')
  #     expect(section.to_label).to eq('§5.2. Star Wars')
  #   end
  # end
end
