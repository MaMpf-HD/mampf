# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Remark, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:valid_remark)).to be_valid
  end

  # test validations - this is done one the level of the parent Medium model

  # test traits

  describe 'with text' do
    it 'has a text' do
      remark = FactoryBot.build(:remark, :with_text)
      expect(remark.text).to be_truthy
    end
  end

  # test methods - NEEDS TO BE IMPLEMENTED
end
