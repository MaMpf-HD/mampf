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
    it 'has the correct number of tags when called with tag_count parameter' do
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

  describe 'with image and normalization' do
    it 'has a normalized image' do
      course = FactoryBot.build(:course, :with_image_and_normalization)
      expect(course.image(:normalized))
        .to be_kind_of(ScreenshotUploader::UploadedFile)
    end
  end

  # test callbacks

  describe 'after save' do
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

  describe 'after adding of a tag' do
    it 'touches the added tag' do
      course = FactoryBot.create(:course)
      tag = FactoryBot.create(:tag)
      tag_update = tag.updated_at
      course.tags << tag
      tag.reload
      new_tag_update = tag.updated_at
      expect(new_tag_update).not_to eq(tag_update)
    end
  end

  describe 'after removing of a tag' do
    it 'touches the removed tag' do
      course = FactoryBot.create(:course)
      tag = FactoryBot.create(:tag)
      course.tags << tag
      tag.reload
      tag_update = tag.updated_at
      course.tags.delete(tag)
      tag.reload
      new_tag_update = tag.updated_at
      expect(new_tag_update).not_to eq(tag_update)
    end
  end
  # Test methods

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

  describe '#sections' do
    it 'returns all sections of the associated lectures' do
      course = FactoryBot.create(:course)
      lecture1 = FactoryBot.create(:lecture, course: course)
      lecture2 = FactoryBot.create(:lecture, course: course)
      chapter1 = FactoryBot.create(:chapter, lecture: lecture1)
      chapter2 = FactoryBot.create(:chapter, lecture: lecture2)
      section1 = FactoryBot.create(:section, chapter: chapter1)
      section2 = FactoryBot.create(:section, chapter: chapter1)
      section3 = FactoryBot.create(:section, chapter: chapter2)
      section4 = FactoryBot.create(:section, chapter: chapter2)
      expect(course.sections).to match_array([section1, section2, section3,
                                              section4])
    end
  end

  context 'class methods for searching' do
    before :all do
      Course.destroy_all
      @course1 = FactoryBot.create(:course)
      @lecture1 = FactoryBot.create(:lecture, course: @course1)
      chapter = FactoryBot.create(:chapter, lecture: @lecture1)
      section = FactoryBot.create(:section, chapter: chapter)
      @lecture2 = FactoryBot.create(:lecture, course: @course1)
      @lesson1 = FactoryBot.create(:lesson, :with_lecture_and_date,
                                   lecture: @lecture1, sections: [section])
      @course2 = FactoryBot.create(:course)
    end

    describe 'self.search_teachables' do
      it 'returns all teachables if :all_teachables flag is set' do
        expect(Course.search_teachables({ all_teachables: '1' }))
          .to match_array([@course1, @course2, @lecture1, @lecture2, @lesson1])
      end

      it 'returns course and all associated lectures and lessons to a course' do
        expect(Course.search_teachables({ teachable_ids:
                                            ["Course-#{@course1.id}"] }))
          .to match_array([@course1, @lecture1, @lecture2, @lesson1])
      end

      it 'returns all selected lectures and their lessons' do
        expect(Course.search_teachables({ teachable_ids:
                                            ["Lecture-#{@lecture1.id}",
                                             "Lecture-#{@lecture2.id}"] }))
          .to match_array([@lecture1, @lecture2, @lesson1])
      end
    end

    describe 'self.search_lecture_ids' do
      it 'returns the ids of the lectures' do
        search_params = { teachable_ids: ['Course-1', 'Lecture-77', 'Lesson-3',
                                          'Lecture-25'] }
        expect(Course.search_lecture_ids(search_params))
          .to match_array(['77', '25'])
      end
    end

    describe 'self.search_course_ids' do
      it 'returns the ids of the lectures' do
        search_params = { teachable_ids: ['Course-10', 'Lecture-77', 'Lesson-3',
                                          'Lecture-25', 'Course-39'] }
        expect(Course.search_course_ids(search_params))
          .to match_array(['10', '39'])
      end
    end

    describe 'self.search_inherited_teachables' do
      it 'returns nil if no teachable_ids param is given' do
        expect(Course.search_inherited_teachables({ foo: 'bar' })).to be_nil
      end

      it 'returns course and all associated lectures and lessons to a course'\
         'encoded as strings' do
        expect(Course.search_inherited_teachables({ teachable_ids:
                                            ["Course-#{@course1.id}"] }))
          .to match_array(["Course-#{@course1.id}", "Lecture-#{@lecture1.id}",
                           "Lecture-#{@lecture2.id}", "Lesson-#{@lesson1.id}"])
      end

      it 'returns all selected lectures and their lessons encoded as strings' do
        expect(Course
                 .search_inherited_teachables(
                   { teachable_ids:
                       ["Lecture-#{@lecture1.id}",
                        "Lecture-#{@lecture2.id}"] }
                 ))
          .to match_array(["Lecture-#{@lecture1.id}",
                           "Lecture-#{@lecture2.id}",
                           "Lesson-#{@lesson1.id}"])
      end
    end
  end

  context 'class methods for select forms' do
    before :all do
      Course.destroy_all
      @user = FactoryBot.create(:confirmed_user)
      @admin = FactoryBot.create(:confirmed_user, admin: true)
      @course1 = FactoryBot.create(:course, title: 'Lineare Algebra 2',
                                            short_title: 'LA2',
                                            editors: [@user])
      @course2 = FactoryBot.create(:course, title: 'Analysis 2',
                                            short_title: 'Ana2')
      @course3 = FactoryBot.create(:course, title: 'Lineare Algebra 1',
                                            short_title: 'LA1',
                                            editors: [@user])
      @course4 = FactoryBot.create(:course, title: 'Analysis 1',
                                            short_title: 'Ana1')
    end

    describe 'self.editable_selection' do
      context 'if user is admin' do
        it 'returns all Courses encoded as strings together with their title '\
           'for viewers, ordered by title' do
          expect(Course.editable_selection(@admin))
            .to eq([['Ana1', "Course-#{@course4.id}"],
                    ['Ana2', "Course-#{@course2.id}"],
                    ['LA1', "Course-#{@course3.id}"],
                    ['LA2', "Course-#{@course1.id}"]])
        end
      end
      context 'if user is non-admin' do
        it 'returns edited Courses encoded as strings together with their '\
           'title for viewers, ordered by title' do
          expect(Course.editable_selection(@user))
            .to eq([['LA1', "Course-#{@course3.id}"],
                    ['LA2', "Course-#{@course1.id}"]])
        end
      end
    end

    describe 'self.select_by_title' do
      it 'returns all Courses with their title and id, ordered by id' do
        expect(Course.select_by_title)
          .to eq([['Analysis 1', @course4.id],
                  ['Analysis 2', @course2.id],
                  ['Lineare Algebra 1', @course3.id],
                  ['Lineare Algebra 2', @course1.id]])
      end
    end
  end

  describe 'questions_count' do
    it 'returns true if there are >=10 questions in the course' do
      course = FactoryBot.create(:course)
      FactoryBot.create_list(:valid_question, 10,
                             teachable: course,
                             independent: true,
                             released: 'all')
      expect(course.enough_questions?).to be true
    end
    it 'returns false if there are <10 questions in the course' do
      course = FactoryBot.create(:course)
      FactoryBot.create_list(:valid_question, 9,
                             teachable: course,
                             independent: true,
                             released: 'all')
      expect(course.enough_questions?).to be false
    end
  end

  context 'complex question methods' do
    before :all do
      @course = FactoryBot.create(:course)
      @lecture1 = FactoryBot.create(:lecture, :released_for_all,
                                    course: @course)
      @lecture2 = FactoryBot.create(:lecture, course: @course)
      @course_questions = FactoryBot.create_list(:valid_question, 7,
                                                 teachable: @course,
                                                 independent: true,
                                                 released: 'all')
      @course_tags = []
      @course_questions.each_with_index do |q, i|
        tag = FactoryBot.create(:tag, title: "Course Tag #{i}")
        @course_tags << tag
        @course.tags << tag
        q.tags << tag
      end
      FactoryBot.create(:valid_question, teachable: @course, independent: false)
      FactoryBot.create(:valid_question, teachable: @course, released: 'locked')
      @lecture1_questions = FactoryBot.create_list(:valid_question, 6,
                                                   teachable: @lecture1,
                                                   independent: true,
                                                   released: 'all')
      @lecture1_tags = []
      @lecture1_questions.each_with_index do |q, i|
        tag = FactoryBot.create(:tag, title: "Lecture Tag #{i}")
        @lecture1_tags << tag
        q.tags << tag
      end
      FactoryBot.create(:valid_question, teachable: @lecture1,
                                         independent: false)
      FactoryBot.create(:valid_question, teachable: @lecture1,
                                         released: 'locked')
      FactoryBot.create(:valid_question, teachable: @lecture1)
      @special_tag1 = FactoryBot.create(:tag, title: 'Special Tag 1')
      @course_questions[4].tags << @special_tag1
      @lecture1_questions[1].tags << @special_tag1
    end

    describe '#questions_count' do
      it 'returns the correct number of questions (released, in course or '\
         'published lectures, independent)' do
        expect(@course.questions_count).to eq 13
      end
    end

    describe '#questions_with_inheritance' do
      it 'returns the correct questions' do
        expect(@course.questions_with_inheritance)
          .to match_array(@course_questions + @lecture1_questions)
      end
    end

    describe '#questions' do
      it 'returns the questions with inheritance if no tags are given' do
        expect(@course.questions(Tag.none))
          .to match_array(@course_questions + @lecture1_questions)
      end

      it 'returns the questions corresponding to the tags' do
        expect(@course.questions([@course_tags[4], @lecture1_tags[5],
                                  @special_tag1]))
          .to match_array([@course_questions[4], @lecture1_questions[5],
                           @lecture1_questions[1]])
      end
    end

    describe '#question_count' do
      it 'returns the correct count if no tags are given' do
        expect(@course.question_count(Tag.none))
          .to eq 13
      end
      it 'returns the correct count ' do
        expect(@course.question_count([@course_tags[4], @lecture1_tags[5],
                                       @special_tag1]))
          .to eq 3
      end
    end

    describe '#question_tags' do
      it 'returns the correct tags' do
        expect(@course.question_tags)
          .to match_array(@course_tags + @lecture1_tags + [@special_tag1])
      end
    end

    describe '#weighted_question_ids' do
      it 'returns the correct hash with questions and their tag count (#1)' do
        expect(@course.weighted_question_ids(@course_questions +
                                             @lecture1_questions,
                                             [@course_tags[4], @special_tag1]))
          .to eq({ @course_questions[4].id => 2,
                   @lecture1_questions[1].id => 1 })
      end
      it 'returns the correct hash with questions and their tag count (#2)' do
        expect(@course.weighted_question_ids(@course_questions +
                                             @lecture1_questions,
                                             [@course_tags[4]]))
          .to eq({ @course_questions[4].id => 1 })
      end
    end

    describe '#select_question_tags_by_title' do
      it 'returns the correct question tags as a array of hashes' do
        course_tag_list = (0..6).to_a.map do |i|
          { value: @course_tags[i].id,
            text: "Course Tag #{i}" }
        end
        lecture_tag_list = (0..5).to_a.map do |i|
          { value: @lecture1_tags[i].id,
            text: "Lecture Tag #{i}" }
        end
        special_tag_list = [{ value: @special_tag1.id,
                              text: 'Special Tag 1' }]
        expect(@course.select_question_tags_by_title)
          .to eq(course_tag_list + lecture_tag_list + special_tag_list)
      end
    end

    describe '#create_random_quiz' do
      it 'returns a valid quiz if tags are given' do
        expect(@course.create_random_quiz!(@course.tags, 5)).to be_valid
      end

      it 'returns a quiz without errors if tags are given' do
        expect(@course.create_random_quiz!(@course.tags, 5).find_errors)
          .to eq([])
      end

      it 'returns a valid quiz if no tags are given' do
        expect(@course.create_random_quiz!([], 5)).to be_valid
      end

      it 'returns a quiz without errors if no tags are given' do
        expect(@course.create_random_quiz!([], 5).find_errors).to eq([])
      end

      it 'returns a valid quiz if question_count is higher than amount of '\
         'tagged questions' do
        expect(@course.create_random_quiz!(@course_tags, 10)).to be_valid
      end

      it 'returns a quiz without errors if no tags are given' do
        expect(@course.create_random_quiz!(@course_tags, 10).find_errors)
          .to eq([])
      end

      it 'has the correct number of questions (#1)' do
        expect(@course.create_random_quiz!(@course.tags, 5).questions_count)
          .to eq 5
      end

      it 'has the correct number of questions (#2)' do
        expect(@course.create_random_quiz!(@course.tags + @lecture1_tags, 10)
                 .questions_count)
          .to eq 10
      end

      it 'has the correct number of questions (#3)' do
        expect(@course.create_random_quiz!(@course.tags, 3).questions_count)
          .to eq 5
      end

      it 'has the correct number of questions (#4)' do
        expect(@course.create_random_quiz!(@course.tags, 10).questions_count)
          .to eq 7
      end

      it 'has questions that relate to the given tags' do
        tags = [@course_tags[0], @course_tags[2], @course_tags[4],
                @course_tags[5], @lecture1_tags[2], @lecture1_tags[3],
                @special_tag1]
        questions = @course.create_random_quiz!(tags, 5).questions
        tagged_questions = [@course_questions[0], @course_questions[2],
                            @course_questions[5], @lecture1_questions[2],
                            @lecture1_questions[3], @course_questions[4],
                            @lecture1_questions[1]]
        expect(questions - tagged_questions).to eq([])
      end
    end
  end

  context 'image methods' do
    before :all do
      @course = FactoryBot.create(:course, :with_image)
    end

    describe '#image_url_with_host' do
      it 'returns nil if there is no image' do
        course = FactoryBot.create(:course)
        expect(course.image_url_with_host).to be_nil
      end

      it 'returns a string with the correct ending' do
        course = FactoryBot.create(:course, :with_image)
        expect(course.image_url_with_host.end_with?(course.image.id)).to be true
      end
    end

    describe '#normalized_image_url_with_host' do
      it 'returns nil if there is no image' do
        course = FactoryBot.create(:course)
        expect(course.normalized_image_url_with_host).to be_nil
      end

      it 'returns nil if there is no normalized image' do
        course = FactoryBot.create(:course, :with_image)
        expect(course.normalized_image_url_with_host).to be_nil
      end

      it 'returns a string with the correct ending' do
        course = FactoryBot.create(:course, :with_image_and_normalization)
        expect(course.normalized_image_url_with_host
                     .end_with?(course.image(:normalized).id)).to be true
      end
    end

    describe '#image_filename' do
      it 'returns nil if there is no image' do
        course = FactoryBot.create(:course)
        expect(course.image_filename).to be_nil
      end

      it 'returns the correct file name' do
        course = FactoryBot.create(:course, :with_image)
        expect(course.image_filename).to eq 'image.png'
      end
    end

    describe '#image_size' do
      it 'returns nil if there is no image' do
        course = FactoryBot.create(:course)
        expect(course.image_size).to be_nil
      end

      it 'returns the correct image file size' do
        course = FactoryBot.create(:course, :with_image)
        expect(course.image_size).to eq 71_933
      end
    end

    describe '#image_resolution' do
      it 'returns nil if there is no image' do
        course = FactoryBot.create(:course)
        expect(course.image_resolution).to be_nil
      end

      it 'returns the correct image resolution' do
        course = FactoryBot.create(:course, :with_image)
        expect(course.image_resolution).to eq '900x600'
      end
    end

    describe 'self.similar_courses' do
      before :all do
        Course.destroy_all
        @course1 = FactoryBot.create(:course, title: 'Algebra 1')
        @course2 = FactoryBot.create(:course, title: 'Algebra 2')
        @course3 = FactoryBot.create(:course, title: 'Analysis 1')
        @course3 = FactoryBot.create(:course, title: 'Analysis 2')
      end

      it 'returns courses whose title is similar to a given string (#1)' do
        expect(Course.similar_courses('Algebra')).to match_array(['Algebra 1',
                                                                  'Algebra 2'])
      end

      it 'returns courses whose title is similar to a given string (#2)' do
        expect(Course.similar_courses('Algbera')).to match_array(['Algebra 1',
                                                                  'Algebra 2'])
      end

      it 'returns courses whose title is similar to a given string (#2)' do
        expect(Course.similar_courses('Ara')).to eq([])
      end
    end
  end
end
