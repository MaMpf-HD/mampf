require 'rails_helper'

RSpec.describe Notion, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.create(:notion, :with_tag)).to be_valid
  end
  it 'is invalid without a title' do
    notion = FactoryBot.build(:notion, title: nil)
    expect(notion).to be_invalid
  end
  it 'can have a custom title' do
    notion = FactoryBot.build(:notion, title: 'customary')
    expect(notion).to be_valid
  end
  it 'is invalid with a duplicate title' do
    notiz=  FactoryBot.create(:notion, title: 'usual BS')
    notion = FactoryBot.build(:notion, title: "usual BS")
    expect(notion).to be_invalid
  end
end
