require 'rails_helper'

describe Teacher do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:teacher)).to be_valid
  end
  it 'is invalid without a name' do
    teacher = FactoryGirl.build(:teacher, name: nil)
    teacher.valid?
    expect(teacher.errors[:name]).to include("can't be blank")
  end
  it 'is invalid without an email' do
    teacher = FactoryGirl.build(:teacher, email: nil)
    teacher.valid?
    expect(teacher.errors[:email]).to include("can't be blank")
  end
  it 'is invalid without a nonsense email' do
    teacher = FactoryGirl.build(:teacher, email: 'letstryit')
    teacher.valid?
    expect(teacher.errors[:email]).to include("is invalid")
  end
  it 'is invalid with a duplicate name' do
    FactoryGirl.create(:teacher, name: 'John Doe')
    teacher = FactoryGirl.build(:teacher, name: 'John Doe')
    teacher.valid?
    expect(teacher.errors[:name]).to include("has already been taken")
  end
  it 'is invalid with a duplicate email' do
    FactoryGirl.create(:teacher, email: 'john@doe.com')
    teacher = FactoryGirl.build(:teacher, email: 'john@doe.com')
    teacher.valid?
    expect(teacher.errors[:email]).to include("has already been taken")
  end
end
