# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Announcement, type: :model do
  it 'has a valid factory' do
     expect(FactoryBot.build(:announcement)).to be_valid
   end

  # test validations

  it 'is invalid without details' do
    announcement = FactoryBot.build(:announcement)
    announcement.details = nil
    expect(announcement).to be_invalid
  end

  # test traits

  describe 'with lecture' do
    before :all do
      @announcement = FactoryBot.build(:announcement, :with_lecture)
    end
    it 'has a valid factory' do
      expect(@announcement).to be_valid
    end
    it 'has a lecture' do
      expect(@announcement.lecture).to be_kind_of(Lecture)
    end
    it 'has the lectures teacher as announcer' do
      expect(@announcement.announcer).to eq @announcement.lecture.teacher
    end
  end

  # test methods - NEEDS TO BE IMPLEMENTED
end
