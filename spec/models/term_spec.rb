require 'rails_helper'

RSpec.describe Term, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:term)).to be_valid
  end
  it 'is invalid without a type' do
    term = FactoryGirl.build(:term, type: nil)
    term.valid?
    expect(term.errors[:type]).to include("can't be blank")
  end
  it 'is invalid without a year' do
    term = FactoryGirl.build(:term, year: nil)
    term.valid?
    expect(term.errors[:year]).to include("can't be blank")
  end
  it 'is invalid if type is not SummerTerm or WinterTerm' do
    term = FactoryGirl.build(:term, type: 'SpringTerm')
    term.valid?
    expect(term.errors[:type]).to include("not a valid type")
  end
  it 'is invalid if year is not a number' do
    term = FactoryGirl.build(:term, year: 'hello')
    term.valid?
    expect(term.errors[:year]).to include("is not a number")
  end
  it 'is invalid if year is not an integer' do
    term = FactoryGirl.build(:term, year: 2017.25)
    term.valid?
    expect(term.errors[:year]).to include("must be an integer")
  end
  it 'is invalid if year is lower than 2000' do
    term = FactoryGirl.build(:term, year: 1999)
    term.valid?
    expect(term.errors[:year]).to include("must be greater than or equal to 2000")
  end
  it 'is invalid if year is higher than 2200' do
    term = FactoryGirl.build(:term, year: 2201)
    term.valid?
    expect(term.errors[:year]).to include("must be less than or equal to 2200")
  end
  it 'is invalid with duplicate type and year' do
    FactoryGirl.create(:term, type: 'SummerTerm', year: 2017)
    term = FactoryGirl.build(:term, type: 'SummerTerm', year: 2017)
    term.valid?
    expect(term.errors[:type]).to include("term already exists")
  end
end
