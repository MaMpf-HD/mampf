# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Import, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:valid_import)).to be_valid
  end

  # test validations

  it 'is invalid without a medium' do
    import = FactoryBot.build(:valid_import, medium: nil)
    expect(import).to be_invalid
  end

  it 'is invalid without a teachable' do
    import = FactoryBot.build(:valid_import)
    import.teachable = nil
    expect(import).to be_invalid
  end

  it 'is invalid with duplicate medium inside same teachable' do
    import = FactoryBot.create(:valid_import)
    new_import = FactoryBot.build(:import)
    new_import.teachable = import.teachable
    new_import.medium = import.medium
    expect(new_import).to be_invalid
  end

  # test traits

  describe 'with teachable' do
    it 'has an associated lecture' do
      import = FactoryBot.build(:import, :with_teachable)
      expect(import.teachable).to be_kind_of(Lecture)
    end
    it 'has an associated course if teachable_sort is :course' do
      import = FactoryBot.build(:import, :with_teachable,
                                teachable_sort: :course)
      expect(import.teachable).to be_kind_of(Course)
    end
    it 'has an associated lesson if teachable_sort is :lesson' do
      import = FactoryBot.build(:import, :with_teachable,
                                teachable_sort: :lesson)
      expect(import.teachable).to be_kind_of(Lesson)
    end
  end
end
