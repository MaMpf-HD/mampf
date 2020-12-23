# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Assignment, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:valid_assignment)).to be_valid
  end

  # test validations

  it 'is invalid without a deadline' do
    assignment = FactoryBot.build(:valid_assignment, deadline: nil)
    expect(assignment).to be_invalid
  end

  it 'is invalid without a title' do
    assignment = FactoryBot.build(:valid_assignment, title: nil)
    expect(assignment).to be_invalid
  end

  it 'is invalid with duplicate title in same lecture' do
    assignment = FactoryBot.create(:valid_assignment, title: 'usual BS')
    lecture = assignment.lecture
    new_assignment = FactoryBot.build(:valid_assignment, lecture: lecture,
                                      title: 'usual BS')
    expect(new_assignment).to be_invalid
  end

  it 'is invalid with inadmissible accepted filetype' do
    assignment = FactoryBot.build(:valid_assignment, accepted_file_type: '.jpg')
    expect(assignment).to be_invalid
  end

  # test traits
  describe 'with lecture' do
    it 'has a lecture' do
      assignment = FactoryBot.build(:assignment, :with_lecture)
      expect(assignment.lecture).to be_kind_of(Lecture)
    end
  end

  # test method - NEEDS TO BE DONE
end
