# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notion, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.create(:valid_notion)).to be_valid
  end

  # test validations

  it 'is invalid without a title' do
    notion = FactoryBot.build(:valid_notion, title: nil)
    expect(notion).to be_invalid
  end
  it 'is invalid with a duplicate title in the same locale' do
    FactoryBot.create(:valid_notion, locale: 'de', title: 'usual BS')
    notion = FactoryBot.build(:valid_notion, locale: 'de', title: 'usual BS')
    expect(notion).to be_invalid
  end
  it 'is invalid if no tag is present and it is persisted' do
    notion = FactoryBot.create(:notion)
    expect(notion).to be_invalid
  end

  # test traits

  describe 'notion with tag' do
    before :all do
      @notion = FactoryBot.build(:notion, :with_tag)
    end
    it 'has a valid factory' do
      expect(@notion).to be_valid
    end
    it 'has a tag' do
      expect(@notion.tag).to be_kind_of(Tag)
    end
  end
end
