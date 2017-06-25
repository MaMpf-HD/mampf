require 'rails_helper'

RSpec.describe Teacher, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:teacher)).to be_valid
  end
  it 'is invalid without a name' do
    teacher = FactoryGirl.build(:teacher, name: nil)
    expect(teacher).to be_invalid
  end
  it 'is invalid without an email' do
    teacher = FactoryGirl.build(:teacher, email: nil)
    expect(teacher).to be_invalid
  end
  it 'is invalid without a nonsense email' do
    teacher = FactoryGirl.build(:teacher, email: 'letstryit')
    expect(teacher).to be_invalid
  end
  it 'is invalid with a duplicate name' do
    FactoryGirl.create(:teacher, name: 'John Doe')
    teacher = FactoryGirl.build(:teacher, name: 'John Doe')
    expect(teacher).to be_invalid
  end
  it 'is invalid with a duplicate email' do
    FactoryGirl.create(:teacher, email: 'john@doe.com')
    teacher = FactoryGirl.build(:teacher, email: 'john@doe.com')
    expect(teacher).to be_invalid
  end
end
