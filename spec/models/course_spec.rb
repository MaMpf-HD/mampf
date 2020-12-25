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
      year = Faker::Number.between(from: 1_000_001, to: 100_000_000)
      term1 = FactoryBot.create(:term, year: year, season: 'SS')
      term2 = FactoryBot.create(:term, year: year, season: 'WS')
      term3 = FactoryBot.create(:term, year: year + 1)
      term4 = FactoryBot.create(:term, year: year + 2)
      @lecture1 = FactoryBot.create(:lecture, course: @course,
                                              teacher: @teacher, term: term1)
      @lecture2 = FactoryBot.create(:lecture, course: @course,
                                              editors: [@editor], term: term2)
      @lecture3 = FactoryBot.create(:lecture, :released_for_all,
                                    course: @course, term: term3)
      @lecture4 = FactoryBot.create(:lecture, :released_for_all,
                                    course: @course, term: term4)
    end

    describe '#subscribable_lectures' do
      it 'returns all lectures for admins' do
        expect(@course.subscribable_lectures(@admin))
          .to match_array([@lecture1, @lecture2, @lecture3, @lecture4])
      end

      it 'returns all given lectures and published lectures for teachers' do
        expect(@course.subscribable_lectures(@teacher))
          .to match_array([@lecture1, @lecture3, @lecture4])
      end

      it 'returns all edited lectures and published lectures for editors' do
        expect(@course.subscribable_lectures(@editor))
          .to match_array([@lecture2, @lecture3, @lecture4])
      end

      it 'returns all published lectures for generic users' do
        expect(@course.subscribable_lectures(@generic_user))
          .to match_array([@lecture3, @lecture4])
      end
    end

    describe '#subscribable_lectures_by_date' do
      it 'returns all lectures (sorted) for admins' do
        expect(@course.subscribable_lectures_by_date(@admin).to_a)
          .to eq([@lecture4, @lecture3, @lecture2, @lecture1])
      end

      it 'returns all given lectures and published lectures (sorted) for '\
         'teachers' do
        expect(@course.subscribable_lectures_by_date(@teacher).to_a)
          .to eq([@lecture4, @lecture3, @lecture1])
      end

      it 'returns all edited lectures and published lectures (sorted) for '\
         'editors' do
        expect(@course.subscribable_lectures_by_date(@editor).to_a)
          .to eq([@lecture4, @lecture3, @lecture2])
      end

      it 'returns all published lectures (sorted) for generic users' do
        expect(@course.subscribable_lectures_by_date(@generic_user).to_a)
          .to eq([@lecture4, @lecture3])
      end
    end
  end

  describe '#restricted?' do
    it 'returns false' do
      course = FactoryBot.build(:course)
      expect(course.restricted?).to be false
    end
  end

  context 'lecture sorting' do
    before :all do
      @course = FactoryBot.create(:course)
      year = Faker::Number.between(from: 1_000_001, to: 100_000_000)
      term1 = FactoryBot.create(:term, year: year, season: 'SS')
      term2 = FactoryBot.create(:term, year: year, season: 'WS')
      term3 = FactoryBot.create(:term, year: year + 1)
      term4 = FactoryBot.create(:term, year: year + 2)
      @lecture1 = FactoryBot.create(:lecture, :released_for_all,
                                    course: @course, term: term1)
      @lecture2 = FactoryBot.create(:lecture, :released_for_all,
                                    course: @course, term: term2)
      @lecture3 = FactoryBot.create(:lecture, course: @course, term: term3)
      @lecture4 = FactoryBot.create(:lecture, course: @course, term: term4)
    end

    describe '#lectures_by_date' do
      it 'returns the lectures sorted by date' do
        expect(@course.lectures_by_date.to_a)
          .to eq([@lecture4, @lecture3, @lecture2, @lecture1])
      end
    end

    describe '#published_lectures_by_date' do
      it 'returns the published lectures sorted by date' do
        expect(@course.published_lectures_by_date.to_a)
          .to eq([@lecture2, @lecture1])
      end
    end
  end

  describe '#select_tags_by_title' do
    it 'returns the correct list' do
      course = FactoryBot.create(:course)
      tag1 = FactoryBot.create(:tag, title: 'Xperience', courses: [course])
      id1 = tag1.id
      tag2 = FactoryBot.create(:tag, title: 'Adventure', courses: [course])
      id2 = tag2.id
      expect(course.select_tags_by_title).to eq [['Adventure', id2],
                                                 ['Xperience', id1]]
    end
  end

  describe '#items' do
    it 'returns all items from the lectures of the course' do
      course = FactoryBot.create(:course)
      lecture1 = FactoryBot.create(:lecture_with_sparse_toc, course: course)
      lecture2 = FactoryBot.create(:lecture_with_sparse_toc, course: course)
      section1 = lecture1.sections.first
      section2 = lecture2.sections.first
      item1 = FactoryBot.create(:item, section: section1)
      item2 = FactoryBot.create(:item, section: section2)
      expect(course.items).to match_array([item1, item2])
    end
  end

  context 'lecture subscriptions' do
    before :all do
      @course = FactoryBot.create(:course)
      year = Faker::Number.between(from: 1_000_001, to: 100_000_000)
      term1 = FactoryBot.create(:term, year: year, season: 'SS')
      term2 = FactoryBot.create(:term, year: year, season: 'WS')
      term3 = FactoryBot.create(:term, year: year + 1)
      term4 = FactoryBot.create(:term, year: year + 2)
      @lecture1 = FactoryBot.create(:lecture, :released_for_all,
                                    course: @course, term: term1)
      @lecture2 = FactoryBot.create(:lecture, :released_for_all,
                                    course: @course, term: term2)
      @lecture3 = FactoryBot.create(:lecture, :released_for_all,
                                    course: @course, term: term3)
      @lecture4 = FactoryBot.create(:lecture, :released_for_all,
                                    course: @course, term: term4,
                                    passphrase: 'test123')
      @user = FactoryBot.create(:confirmed_user,
                                lectures: [@lecture1, @lecture2, @lecture3])
    end

    describe '#subscribed_lectures' do
      it 'returns all the subscribed lectures of the user' do
        expect(@course.subscribed_lectures(@user))
          .to match_array([@lecture1, @lecture2, @lecture3])
      end
    end

    describe '#subscribed_lectures_by_date' do
      it 'returns all the subscribed lectures (sorted) of the user' do
        expect(@course.subscribed_lectures_by_date(@user).to_a)
          .to eq([@lecture3, @lecture2, @lecture1])
      end
    end

    describe '#to_be_authorized_lectures' do
      it 'returns all the nonsubscribed lectures of the user with passphrase' do
        expect(@course.to_be_authorized_lectures(@user))
          .to match_array([@lecture4])
      end
    end

    describe '#subscribed_by?' do
      before :each do
        @user = FactoryBot.create(:confirmed_user)
        @course = FactoryBot.create(:course)
      end

      it 'returns true if a lecture of the course was subscribed by user' do
        lecture = FactoryBot.create(:lecture, course: @course)
        @user.lectures << lecture
        expect(@course.subscribed_by?(@user)).to be true
      end

      it 'returns false if no lecture of the course was subscribed by user' do
        expect(@course.subscribed_by?(@user)).to be false
      end
    end

    describe '#edited_by?' do
      before :all do
        @user = FactoryBot.create(:confirmed_user)
      end
      it 'returns true if the course is edited by user' do
        course = FactoryBot.create(:course, editors: [@user])
        expect(course.edited_by?(@user)).to be true
      end
      it 'returns false if course is not edited by user' do
        course = FactoryBot.create(:course)
        expect(course.edited_by?(@user)).to be false
      end
    end

    describe '#addable_by?' do
      before :each do
        @user = FactoryBot.create(:confirmed_user)
      end
      it 'returns true if the course is edited by user' do
        course = FactoryBot.create(:course, editors: [@user])
        expect(course.addable_by?(@user)).to be true
      end
      it 'returns true if a lecture of the course is edited by user' do
        course = FactoryBot.create(:course)
        FactoryBot.create(:lecture, course: course, editors: [@user])
        expect(course.addable_by?(@user)).to be true
      end
      it 'returns true if a lecture of the course has the user as teacher' do
        course = FactoryBot.create(:course)
        FactoryBot.create(:lecture, course: course, teacher: @user)
        expect(course.addable_by?(@user)).to be true
      end
      it 'returns false if none of the above is true' do
        course = FactoryBot.create(:course)
        FactoryBot.create(:lecture, course: course)
        expect(course.addable_by?(@user)).to be false
      end
    end

    describe '#removable_by?' do
      before :all do
        @user = FactoryBot.create(:confirmed_user)
      end
      it 'returns true if the course is edited by user' do
        course = FactoryBot.create(:course, editors: [@user])
        expect(course.removable_by?(@user)).to be true
      end
      it 'returns false if no lecture of the course is not edited by user' do
        course = FactoryBot.create(:course)
        expect(course.removable_by?(@user)).to be false
      end
    end

    context 'media and their items with inheritance' do
      before :all do
        DatabaseCleaner.clean
        @course = FactoryBot.create(:course, short_title: 'LA2')
        term = FactoryBot.create(:term, year: 2020, season: 'SS')
        lecture = FactoryBot.create(:lecture_with_sparse_toc, course: @course,
                                                              term: term)
        lesson = FactoryBot.create(:valid_lesson, lecture: lecture)
        @course_medium = FactoryBot.create(:course_medium,
                                           teachable: @course,
                                           description: 'p-adische Zahlen')
        @lecture_medium = FactoryBot.create(:lecture_medium,
                                            teachable: lecture,
                                            description: 'Gruppenring')
        @lesson_medium = FactoryBot.create(:lesson_medium,
                                           teachable: lesson,
                                           description: 'exakte Folge')
      end

      describe '#media_with_inheritance' do
        it 'returns all media form course and associated lectures, lessons' do
          expect(@course.media_with_inheritance)
            .to match_array([@course_medium, @lecture_medium, @lesson_medium])
        end
      end

      describe '#media_items_with_inheritance' do
        it 'returns all items with their title and id' do
          item1 = FactoryBot.create(:item, sort: 'remark', ref_number: '1.2',
                                           medium: @course_medium)
          item2 = FactoryBot.create(:item, sort: 'theorem', ref_number: '3.4',
                                           medium: @lecture_medium)
          item3 = FactoryBot.create(:item, sort: 'example', ref_number: '5.6',
                                           medium: @lesson_medium)
          self_item1 = Item.find_by(sort: 'self', medium: @course_medium)
          self_item2 = Item.find_by(sort: 'self', medium: @lecture_medium)
          self_item3 = Item.find_by(sort: 'self', medium: @lesson_medium)
          expect(@course.media_items_with_inheritance)
            .to match_array([['Bem. 1.2 ', item1.id],
                             ['SS 20, Satz 3.4 ', item2.id],
                             ['SS 20, Bsp. 5.6 ', item3.id],
                             ['Worked Example, p-adische Zahlen',
                              self_item1.id],
                             ['SS 20, Worked Example, Gruppenring',
                              self_item2.id],
                             ['SS 20, Lektion, exakte Folge', self_item3.id]])
        end
      end
    end
  end
end
