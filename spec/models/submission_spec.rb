# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Submission, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:valid_submission)).to be_valid
  end

  # test validations

  it 'is invalid without an assignment' do
    expect(FactoryBot.build(:valid_submission, assignment: nil)).to be_invalid
  end

  it 'is invalid without a tutorial' do
    expect(FactoryBot.build(:valid_submission, tutorial: nil)).to be_invalid
  end

  it 'is invalid if lecture does not match' do
    submission = FactoryBot.build(:valid_submission)
    submission.assignment.lecture = FactoryBot.build(:lecture)
    expect(submission).to be_invalid
  end

  # test traits

  describe 'with assignment' do
    it 'has an assignment' do
      submission = FactoryBot.build(:valid_submission, :with_assignment)
      expect(submission.assignment).to be_kind_of(Assignment)
    end
  end

  describe 'with tutorial' do
    it 'has a tutorial' do
      submission = FactoryBot.build(:valid_submission, :with_tutorial)
      expect(submission.tutorial).to be_kind_of(Tutorial)
    end
  end

  describe 'with users' do
    it 'has two users' do
      submission = FactoryBot.build(:valid_submission, :with_users)
      expect(submission.users.size).to eq 2
    end
    it 'has the correct number of users when users_count parameter is used' do
      submission = FactoryBot.build(:valid_submission, :with_users,
                                    users_count: 4)
      expect(submission.users.size).to eq 4
    end
  end

  describe 'with manuscript' do
    it 'has a manuscript' do
      submission = FactoryBot.build(:valid_submission, :with_manuscript)
      expect(submission.manuscript)
        .to be_kind_of(SubmissionUploader::UploadedFile)
    end
  end

  describe 'with correction' do
    it 'has a correction' do
      submission = FactoryBot.build(:valid_submission, :with_correction)
      expect(submission.correction)
        .to be_kind_of(CorrectionUploader::UploadedFile)
    end
  end
end
