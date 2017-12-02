require 'rails_helper'

RSpec.describe Link, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:link)).to be_valid
  end
  it 'is invalid if link already exists' do
    medium = FactoryBot.create(:medium)
    linked_medium = FactoryBot.create(:medium)
    FactoryBot.create(:link, medium: medium, linked_medium: linked_medium)
    duplicate_link = FactoryBot.build(:link, medium: medium,
                                             linked_medium: linked_medium)
    expect(duplicate_link).to be_invalid
  end
  it 'destroys a link if it is a self-link' do
    medium = FactoryBot.create(:medium)
    link = FactoryBot.create(:link, medium: medium,
                                    linked_medium: medium)
    id = link.id
    expect(Link.exists?(id)).to be false
  end
  it 'creates an inverse if link is not self-inverse' do
    first_medium = FactoryBot.create(:medium)
    second_medium = FactoryBot.create(:medium)
    FactoryBot.create(:link, medium: first_medium, linked_medium: second_medium)
    expect(Link.exists?(medium: second_medium, linked_medium: first_medium)).to be true
  end
  it 'destroys the inverse after deletion if link is not self-inverse' do
    first_medium = FactoryBot.create(:medium)
    second_medium = FactoryBot.create(:medium)
    link = FactoryBot.create(:link, medium: first_medium,
                                    linked_medium: second_medium)
    link.destroy
    expect(Link.exists?(medium: second_medium, linked_medium: first_medium)).to be false
  end
end
