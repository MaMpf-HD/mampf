# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Clicker, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:valid_clicker)).to be_valid
  end

  # test validations
  it 'is invalid without a title' do
    clicker = FactoryBot.build(:valid_clicker, title: nil)
    expect(clicker).to be_invalid
  end

  it 'is invalid with duplicate title for same editor' do
    clicker = FactoryBot.create(:valid_clicker, title: 'usual BS')
    editor = clicker.editor
    new_clicker = FactoryBot.build(:valid_clicker, editor: editor,
                                                   title: 'usual BS')
    expect(new_clicker).to be_invalid
  end

  # test traits and subfactories

  describe 'with editor' do
    it 'has an editor' do
      clicker = FactoryBot.build(:clicker, :with_editor)
      expect(clicker.editor).to be_kind_of(User)
    end
  end

  describe 'with question' do
    it 'has a question' do
      clicker = FactoryBot.build(:clicker, :with_question)
      expect(clicker.question).to be_kind_of(Question)
    end
  end

  describe 'open' do
    it 'is open' do
      clicker = FactoryBot.build(:clicker, :open)
      expect(clicker.open).to be true
    end
  end

  describe 'with modified alternatives' do
    it 'has the correct amount of alternatives' do
      clicker = FactoryBot.create(:valid_clicker, :with_modified_alternatives,
                                  alternative_count: 5)
      expect(clicker.alternatives).to eq 5
    end
  end

  # test methods - NEEDS TO BE DONE
end
