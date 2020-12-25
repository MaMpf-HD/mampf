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

  describe '#title_for_viewers' do
    it 'returns the correct title for viewers' do
      course = FactoryBot.build(:course, short_title: 'BS')
      expect(course.title_for_viewers).to eq('BS')
    end
  end

  describe '#long_title' do
    it 'returns the correct long title' do
      course = FactoryBot.build(:course, title: 'usual BS')
      expect(course.long_title).to eq('usual BS')
    end
  end

  describe '#title_no_term' do
    it 'returns the correct title' do
      course = FactoryBot.build(:course, title: 'usual BS')
      expect(course.title_no_term).to eq('usual BS')
    end
  end

  describe '#locale_with_inheritance' do
    it 'returns the correct locale' do
      course = FactoryBot.build(:course, locale: 'br')
      expect(course.locale_with_inheritance).to eq('br')
    end
  end

  describe '#card_header' do
    it 'returns the correct card header' do
      course = FactoryBot.build(:course, title: 'usual BS')
      expect(course.card_header).to eq('usual BS')
    end
  end

  describe '#published?' do
    it 'returns true' do
      course = FactoryBot.build(:course, title: 'usual BS')
      expect(course.published?).to be true
    end
  end

  describe '#card_header_path' do
    it 'returns nil' do
      course = FactoryBot.build(:course)
      user = FactoryBot.build(:confirmed_user)
      expect(course.card_header_path(user)).to be_nil
    end
  end

  describe '#irrelevant?' do
    before :each do
      @course = FactoryBot.build(:course)
    end

    it 'returns false if the course has lectures' do
      FactoryBot.build(:lecture, course: @course)
      expect(@course.irrelevant?).to be false
    end

    it 'returns false if the course has media' do
      FactoryBot.build(:course_medium, teachable: @course)
      expect(@course.irrelevant?).to be false
    end

    it 'returns false if the course is not persisted' do
      expect(@course.irrelevant?).to be false
    end

    it 'returns true if the course is persisted and has no lectures or media' do
      @course.save
      expect(@course.irrelevant?).to be true
    end
  end

  describe '#published_lectures' do
    it 'returns the published lectures' do
      course = FactoryBot.create(:course)
      published_lectures = FactoryBot.create_list(:lecture, 3,
                                                  :released_for_all,
                                                  course: course)
      FactoryBot.create_list(:lecture, 2, course: course)
      expect(course.published_lectures).to match_array(published_lectures)
    end
  end

  context 'subscribable lectures' do
    before :all do
      @admin = FactoryBot.create(:confirmed_user, admin: true)
      @editor = FactoryBot.create(:confirmed_user)
      @teacher = FactoryBot.create(:confirmed_user)
      @generic_user = FactoryBot.create(:confirmed_user)
      @course = FactoryBot.create(:course)
      year = Faker::Number.between(from: 1000001, to: 100000000)
      term_1 = FactoryBot.create(:term, year: year, season: 'SS')
      term_2 = FactoryBot.create(:term, year: year, season: 'WS')
      term_3 = FactoryBot.create(:term, year: year + 1)
      term_4 = FactoryBot.create(:term, year: year + 2)
      @lecture_1 = FactoryBot.create(:lecture, course: @course,
                                     teacher: @teacher, term: term_1)
      @lecture_2 = FactoryBot.create(:lecture, course: @course,
                                     editors: [@editor], term: term_2)
      @lecture_3 = FactoryBot.create(:lecture, :released_for_all,
                                     course: @course, term: term_3)
      @lecture_4 = FactoryBot.create(:lecture, :released_for_all,
                                     course: @course, term: term_4)
    end

    describe '#subscribable_lectures' do
      it 'returns all lectures for admins' do
        expect(@course.subscribable_lectures(@admin))
          .to match_array([@lecture_1, @lecture_2, @lecture_3,@lecture_4])
      end

      it 'returns all given lectures and published lectures for teachers' do
        expect(@course.subscribable_lectures(@teacher))
          .to match_array([@lecture_1, @lecture_3, @lecture_4])
      end

      it 'returns all edited lectures and published lectures for editors' do
        expect(@course.subscribable_lectures(@editor))
          .to match_array([@lecture_2, @lecture_3, @lecture_4])
      end

      it 'returns all published lectures for generic users' do
        expect(@course.subscribable_lectures(@generic_user))
          .to match_array([@lecture_3, @lecture_4])
      end
    end

    describe '#subscribable_lectures_by_date' do
      it 'returns all lectures (sorted) for admins' do
        expect(@course.subscribable_lectures_by_date(@admin).to_a)
          .to eq([@lecture_4, @lecture_3, @lecture_2, @lecture_1])
      end

      it 'returns all given lectures and published lectures (sorted) for '\
         'teachers' do
        expect(@course.subscribable_lectures_by_date(@teacher).to_a)
          .to eq([@lecture_4, @lecture_3, @lecture_1])
      end

      it 'returns all edited lectures and published lectures (sorted) for '\
         'editors' do
        expect(@course.subscribable_lectures_by_date(@editor).to_a)
          .to eq([@lecture_4, @lecture_3, @lecture_2])
      end

      it 'returns all published lectures (sorted) for generic users' do
        expect(@course.subscribable_lectures_by_date(@generic_user).to_a)
          .to eq([@lecture_4, @lecture_3])
      end
    end
  end

  describe '#restricted?' do
    it 'returns false' do
      course = FactoryBot.build(:course)
      expect(course.restricted?).to be false
    end
  end

  describe '#select_tags_by_title' do
    it 'returns the correct list' do
      course = FactoryBot.create(:course)
      tag_1 = FactoryBot.create(:tag, title: 'Xperience', courses: [course])
      id_1 = tag_1.id
      tag_2 = FactoryBot.create(:tag, title: 'Adventure', courses: [course])
      id_2 = tag_2.id
      expect(course.select_tags_by_title).to eq [['Adventure', id_2],
                                                 ['Xperience', id_1]]
    end
  end
end
