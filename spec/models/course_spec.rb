# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Course, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:course)).to be_valid
  end

  # Test validations

  it 'is invalid without a title' do
    course = FactoryBot.build(:course, title: nil)
    expect(course).to be_invalid
  end
  it 'is invalid with a duplicate title' do
    FactoryBot.create(:course, title: 'usual bs')
    course = FactoryBot.build(:course, title: 'usual bs')
    expect(course).to be_invalid
  end
  it 'is invalid without a short title' do
    course = FactoryBot.build(:course, short_title: nil)
    expect(course).to be_invalid
  end
  it 'is invalid with a duplicate short title' do
    FactoryBot.create(:course, short_title: 'usual bs')
    course = FactoryBot.build(:course, short_title: 'usual bs')
    expect(course).to be_invalid
  end

  # Test traits

  describe 'course with tags' do
    before :all do
      @course = FactoryBot.build(:course, :with_tags)
    end
    it 'has a valid factory' do
      expect(@course).to be_valid
    end
    it 'has tags' do
      expect(@course.tags).not_to be_nil
    end
    it 'has 3 tags when called without tag_count parameter' do
      expect(@course.tags.size).to eq 3
    end
    it 'has correct number of tags when called with tag_count parameter' do
      course = FactoryBot.build(:course, :with_tags, tag_count: 5)
      expect(course.tags.size).to eq 5
    end
  end

  describe 'term independent course' do
    course = FactoryBot.build(:course, :term_independent)
    it 'has a valid factory' do
      expect(course).to be_valid
    end
    it 'is term independent' do
      expect(course.term_independent).to be true
    end
  end

  describe 'course with organizational stuff' do
    course = FactoryBot.build(:course, :with_organizational_stuff)
    it 'has a valid factory' do
      expect(course).to be_valid
    end
    it 'has organzational flag set to true' do
      expect(course.organizational).to be true
    end
    it 'has an organizational concept' do
      expect(course.organizational_concept).to be_truthy
    end
  end

  describe 'course with locale de' do
    course = FactoryBot.build(:course, :locale_de)
    it 'has a valid factory' do
      expect(course).to be_valid
    end
    it 'has locale de' do
      expect(course.locale).to eq 'de'
    end
  end

  describe 'with image' do
    it 'has an image' do
      course = FactoryBot.build(:course, :with_image)
      expect(course.image).to be_kind_of(ScreenshotUploader::UploadedFile)
    end
  end

  # test callbacks

  context 'after save' do
    before :all do
      @course = FactoryBot.create(:course)
      @lecture = FactoryBot.create(:lecture_with_sparse_toc, course: @course)
      @lesson = FactoryBot.create(:valid_lesson, lecture: @lecture)
    end

    it 'touches all media related to the course (with inheritance)' do
      course_medium = FactoryBot.create(:course_medium, teachable: @course)
      lecture_medium = FactoryBot.create(:lecture_medium, teachable: @lecture)
      lesson_medium = FactoryBot.create(:lesson_medium, teachable: @lecture)
      updated_ats = [course_medium.updated_at, lecture_medium.updated_at,
                     lesson_medium.updated_at]
      @course.save
      course_medium.reload
      lecture_medium.reload
      lesson_medium.reload
      new_updated_ats = [course_medium.updated_at, lecture_medium.updated_at,
                         lesson_medium.updated_at]
      comparison = [0, 1, 2].map { |i| updated_ats[i] == new_updated_ats[i] }
      expect(comparison).to eq [false, false, false]
    end

    it 'touches all lectures and lessons related to the course' do
      updated_ats = [@lecture.updated_at, @lesson.updated_at]
      @course.save
      @lecture.reload
      @lesson.reload
      new_updated_ats = [@lecture.updated_at, @lesson.updated_at]
      comparison = [0, 1].map { |i| updated_ats[i] == new_updated_ats[i] }
      expect(comparison).to eq [false, false]
    end
  end

  # Test methods -- NEEDS TO BE REFACTORED

  describe '#course' do
    it 'returns self' do
      course = FactoryBot.build(:course)
      expect(course.course).to eq course
    end
  end

  describe '#lecture' do
    it 'returns nil' do
      course = FactoryBot.build(:course)
      expect(course.lecture).to be_nil
    end
  end

  describe '#lesson' do
    it 'returns nil' do
      course = FactoryBot.build(:course)
      expect(course.lesson).to be_nil
    end
  end

  describe '#media_scope' do
    it 'returns self' do
      course = FactoryBot.build(:course)
      expect(course.media_scope).to eq course
    end
  end

  describe '#selector_value' do
    it 'returns the correct selector value' do
      course = FactoryBot.create(:course)
      expect(course.selector_value).to eq "Course-#{course.id}"
    end
  end

  describe '#to_label' do
    it 'returns the correct label' do
      course = FactoryBot.build(:course, title: 'usual bs')
      expect(course.to_label).to eq('usual bs')
    end
  end

  describe '#compact_title' do
    it 'returns the correct compact title' do
      course = FactoryBot.build(:course, short_title: 'BS')
      expect(course.compact_title).to eq('BS')
    end
  end
end
