# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tutorial, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:tutorial)).to be_valid
  end

  # test validations

  it 'is invalid without a lecture' do
    expect(FactoryBot.build(:tutorial, lecture: nil)).to be_invalid
  end

  it 'is invalid without a title' do
    expect(FactoryBot.build(:tutorial, title: nil)).to be_invalid
  end

  it 'is invalid with duplicate title in same lecture' do
    tutorial = FactoryBot.create(:tutorial)
    lecture = tutorial.lecture
    title = tutorial.title
    new_tutorial = FactoryBot.build(:tutorial, lecture: lecture, title: title)
    expect(new_tutorial).to be_invalid
  end

  # test traits

  describe 'with tutors' do
    it 'has a tutor' do
      tutorial = FactoryBot.build(:tutorial, :with_tutors)
      expect(tutorial.tutors.size).to eq 1
    end
    it 'has the correct number of tutors if tutors_count is supplied' do
      tutorial = FactoryBot.build(:tutorial, :with_tutors, tutors_count: 3)
      expect(tutorial.tutors.size).to eq 3
    end
  end
end
