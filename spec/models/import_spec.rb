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
      expect(import.teachable.is_a?(Lecture)).to be true
    end
  end
end
