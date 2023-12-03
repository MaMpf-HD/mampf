# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Link, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:link)).to be_valid
  end

  # test validations

  it 'is invalid if link already exists' do
    medium = FactoryBot.create(:valid_medium)
    linked_medium = FactoryBot.create(:valid_medium)
    FactoryBot.create(:link, medium: medium, linked_medium: linked_medium)
    duplicate_link = FactoryBot.build(:link, medium: medium,
                                             linked_medium: linked_medium)
    expect(duplicate_link).to be_invalid
  end

  # test callbacks

  it 'destroys a link if it is a self-link' do
    medium = FactoryBot.create(:valid_medium)
    link = FactoryBot.create(:link, medium: medium,
                                    linked_medium: medium)
    id = link.id
    expect(Link.exists?(id)).to be false
  end

  it 'creates an inverse if link is not self-inverse' do
    first_medium = FactoryBot.create(:valid_medium)
    second_medium = FactoryBot.create(:valid_medium)
    FactoryBot.create(:link, medium: first_medium, linked_medium: second_medium)
    expect(Link.exists?(medium: second_medium, linked_medium: first_medium))
      .to be true
  end

  it 'destroys the inverse after deletion if link is not self-inverse' do
    first_medium = FactoryBot.create(:valid_medium)
    second_medium = FactoryBot.create(:valid_medium)
    link = FactoryBot.create(:link, medium: first_medium,
                                    linked_medium: second_medium)
    link.destroy
    expect(Link.exists?(medium: second_medium, linked_medium: first_medium))
      .to be false
  end
end
