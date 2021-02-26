# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lecture, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:lecture)).to be_valid
  end

  # Test validations

  it 'is invalid without a course' do
    lecture = FactoryBot.build(:lecture, course: nil)
    expect(lecture).to be_invalid
  end
  it 'is invalid without a teacher' do
    lecture = FactoryBot.build(:lecture, teacher: nil)
    expect(lecture).to be_invalid
  end
  it 'is invalid if duplicate combination of course, teacher and term' do
    course = FactoryBot.create(:course)
    teacher = FactoryBot.create(:confirmed_user)
    term = FactoryBot.create(:term)
    FactoryBot.create(:lecture, course: course, teacher: teacher, term: term)
    lecture = FactoryBot.build(:lecture, course: course, teacher: teacher,
                                         term: term)
    expect(lecture).to be_invalid
  end
  it 'is invalid if content mode is illegal' do
    expect(FactoryBot.build(:lecture, content_mode: 'bs')).to be_invalid
  end
  it 'is invalid if sort is illegal' do
    expect(FactoryBot.build(:lecture, sort: 'bs')).to be_invalid
  end
  it 'is invalid if there is no term but course is term dependent' do
    expect(FactoryBot.build(:lecture, term: nil)).to be_invalid
  end
  it 'is invalid if there is a term but course is term independent' do
    expect(FactoryBot.build(:lecture, :term_independent,
                            term: FactoryBot.build(:term))).to be_invalid
  end
  it 'is invalid if there is more than one lecture on a term independent '\
     'course' do
    lecture = FactoryBot.create(:lecture, :term_independent)
    new_lecture = FactoryBot.build(:lecture, term: nil,
                                    course: lecture.course)
    expect(new_lecture).to be_invalid
  end
  it 'is invalid if submission_max_team_size is not an integer' do
    expect(FactoryBot.build(:lecture, submission_max_team_size: 3.5))
      .to be_invalid
  end
  it 'is invalid if submission_max_team_size is < 1' do
    expect(FactoryBot.build(:lecture, submission_max_team_size: 0))
      .to be_invalid
  end
  it 'is invalid if submission_grace_period is not an integer' do
    expect(FactoryBot.build(:lecture, submission_grace_period: 3.5))
      .to be_invalid
  end
  it 'is invalid if submission_grace_period is < 0' do
    expect(FactoryBot.build(:lecture, submission_grace_period: -1))
      .to be_invalid
  end

  # Test traits

  describe 'lecture with organizational stuff' do
    before :all do
      @lecture = FactoryBot.build(:lecture, :with_organizational_stuff)
    end
    it 'has a valid factory' do
      expect(@lecture).to be_valid
    end
    it 'has organizational flag set to true' do
      expect(@lecture.organizational).to be true
    end
    it 'has an organizational concept' do
      expect(@lecture.organizational_concept).to be_truthy
    end
  end

  describe 'lecture which is released for all' do
    before :all do
      @lecture = FactoryBot.build(:lecture, :released_for_all)
    end
    it 'has a valid factory' do
      expect(@lecture).to be_valid
    end
    it 'is released for all' do
      expect(@lecture.released).to eq 'all'
    end
  end

  describe 'term independent lecture' do
    before :all do
      @lecture = FactoryBot.build(:lecture, :term_independent)
    end
    it 'has a valid factory' do
      expect(@lecture).to be_valid
    end
    it 'has no associated term' do
      expect(@lecture.term).to be_nil
    end
  end

  describe 'with table of contents' do
    before :all do
      @lecture = FactoryBot.build(:lecture, :with_toc)
    end
    it 'has 3 chapters' do
      expect(@lecture.chapters.size).to eq 3
    end
    it 'has 3 sections in each chapter' do
      expect(@lecture.chapters.map { |c| c.sections.size }).to eq [3, 3, 3]
    end
  end

  describe 'with sparse table of contents' do
    before :all do
      @lecture = FactoryBot.build(:lecture, :with_sparse_toc)
    end
    it 'has one chapter' do
      expect(@lecture.chapters.size).to eq 1
    end
    it 'has one sections in each chapter' do
      expect(@lecture.chapters.map { |c| c.sections.size }).to eq [1]
    end
  end

  describe 'with forum' do
    before :all do
      @lecture = FactoryBot.build(:lecture, :with_forum)
    end
    it 'has a forum_id' do
      expect(@lecture.forum_id).not_to be_nil
    end
    it 'has an actual forum' do
      expect(Thredded::Messageboard.find_by_id(@lecture.forum_id))
        .not_to be_nil
    end
  end

  # test callbacks

  describe 'after adding/removing a lesson' do
    before :each do
      @medium = FactoryBot.create(:lesson_medium)
      @lesson1 = @medium.teachable
      @lecture = @lesson1.lecture
      @lesson2 = FactoryBot.create(:valid_lesson, lecture: @lecture)
      @updated_ats = [@medium.updated_at, @lesson1.updated_at]
    end

    it 'touches lessons of the lecture and their media if a lesson is '\
       'added' do
      lesson3 = FactoryBot.build(:valid_lesson)
      @lecture.lessons << lesson3
      @medium.reload
      @lesson1.reload
      new_updated_ats = [@medium.updated_at, @lesson1.updated_at]
      comparison = [0, 1].map { |i| @updated_ats[i] == new_updated_ats[i] }
      expect(comparison).to eq [false, false]
    end

    it 'touches lessons of the lecture and their media if a lesson is '\
       'removed' do
      @lecture.lessons.delete(@lesson2)
      @medium.reload
      @lesson1.reload
      new_updated_ats = [@medium.updated_at, @lesson1.updated_at]
      comparison = [0, 1].map { |i| @updated_ats[i] == new_updated_ats[i] }
      expect(comparison).to eq [false, false]
    end
  end

  describe 'after save' do
    it 'touches all related media/lessons/chapter/sections' do
      medium = FactoryBot.create(:lesson_medium)
      lesson = medium.teachable
      lecture = lesson.lecture
      chapter = lecture.chapters.first
      section = chapter.sections.first
      updated_ats = [medium.updated_at, lesson.updated_at,
                     chapter.updated_at, section.updated_at]
      lecture.save
      medium.reload
      lesson.reload
      chapter.reload
      section.reload
      new_updated_ats = [medium.updated_at, lesson.updated_at,
                         chapter.updated_at, section.updated_at]
      comparison = (0..3).to_a.map { |i| updated_ats[i] == new_updated_ats[i] }
      expect(comparison).to eq [false, false, false, false]
    end

    it 'removes the teacher as editor' do
      lecture = FactoryBot.build(:lecture)
      lecture.editors = [lecture.teacher]
      lecture.save
      expect(lecture.editors).to match_array([])
    end
  end

  describe 'before destroy' do
    it 'destroys the forum' do
      lecture = FactoryBot.create(:lecture)
      forum = Thredded::Messageboard.create(name: Faker::Book.title)
      id = forum.id
      lecture.update(forum_id: forum.id)
      lecture.destroy
      expect(Thredded::Messageboard.find_by_id(id)).to be_nil
    end
  end

  # Test methods -- NEEDS TO BE REFACTORED

  describe '#lecture' do
    it 'returns self' do
      lecture = FactoryBot.build(:lecture)
      expect(lecture.lecture).to eq lecture
    end
  end

  describe '#lesson' do
    it 'returns nil' do
      lecture = FactoryBot.build(:lecture)
      expect(lecture.lesson).to be_nil
    end
  end

  describe '#media_scope' do
    it 'returns self' do
      lecture = FactoryBot.build(:lecture)
      expect(lecture.media_scope).to eq lecture
    end
  end

  describe '#selector_value' do
    it 'returns the correct selector' do
      lecture = FactoryBot.create(:lecture)
      expect(lecture.selector_value).to eq "Lecture-#{lecture.id}"
    end
  end

  describe '#title' do
    context 'if course is term independent' do
      it 'returns the correct title' do
        course = FactoryBot.build(:course, :term_independent,
                                  title: 'Algebra 1')
        lecture = FactoryBot.build(:lecture, :term_independent, course: course)
        expect(lecture.title).to eq 'Algebra 1'
      end
    end

    context 'if course is not term independent' do
      it 'returns the correct title' do
        I18n.locale = 'de'
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term)
        expect(lecture.title).to eq '(V) Algebra 1, SS 2020'
      end
    end
  end

  describe '#title_no_term' do
    context 'if course is term independent' do
      it 'returns the correct title' do
        course = FactoryBot.build(:course, :term_independent,
                                  title: 'Algebra 1')
        lecture = FactoryBot.build(:lecture, :term_independent, course: course)
        expect(lecture.title_no_term).to eq 'Algebra 1'
      end
    end

    context 'if course is not term independent' do
      it 'returns the correct title' do
        I18n.locale = 'de'
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term)
        expect(lecture.title_no_term).to eq '(V) Algebra 1'
      end
    end
  end

  describe '#to_label' do
    context 'if course is term independent' do
      it 'returns the correct title' do
        course = FactoryBot.build(:course, :term_independent,
                                  title: 'Algebra 1')
        lecture = FactoryBot.build(:lecture, :term_independent, course: course)
        expect(lecture.to_label).to eq 'Algebra 1'
      end
    end

    context 'if course is not term independent' do
      it 'returns the correct title' do
        I18n.locale = 'de'
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term)
        expect(lecture.to_label).to eq '(V) Algebra 1, SS 2020'
      end
    end
  end

  describe '#compact_title' do
    context 'if course is term independent' do
      it 'returns the correct title' do
        course = FactoryBot.build(:course, :term_independent,
                                  title: 'Algebra 1', short_title: 'Alg1')
        lecture = FactoryBot.build(:lecture, :term_independent, course: course)
        expect(lecture.compact_title).to eq 'Alg1'
      end
    end

    context 'if course is not term independent' do
      it 'returns the correct title' do
        I18n.locale = 'de'
        course = FactoryBot.build(:course, title: 'Algebra 1',
                                  short_title: 'Alg1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term)
        expect(lecture.compact_title).to eq 'V.Alg1.SS20'
      end
    end
  end

  describe '#short_title' do
    context 'if course is term independent' do
      it 'returns the correct title' do
        course = FactoryBot.build(:course, :term_independent,
                                  title: 'Algebra 1', short_title: 'Alg1')
        lecture = FactoryBot.build(:lecture, :term_independent, course: course)
        expect(lecture.short_title).to eq 'Alg1'
      end
    end

    context 'if course is not term independent' do
      it 'returns the correct title' do
        I18n.locale = 'de'
        course = FactoryBot.build(:course, title: 'Algebra 1',
                                  short_title: 'Alg1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term)
        expect(lecture.short_title).to eq '(V) Alg1 SS 20'
      end
    end
  end

  describe '#title_for_viewers' do
    context 'if course is term independent' do
      it 'returns the correct title' do
        course = FactoryBot.build(:course, :term_independent,
                                  title: 'Algebra 1', short_title: 'Alg1')
        lecture = FactoryBot.build(:lecture, :term_independent, course: course)
        expect(lecture.title_for_viewers).to eq 'Alg1'
      end
    end

    context 'if course is not term independent' do
      it 'returns the correct title' do
        I18n.locale = 'de'
        course = FactoryBot.build(:course, title: 'Algebra 1',
                                  short_title: 'Alg1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term)
        expect(lecture.title_for_viewers).to eq '(V) Alg1 SS 20'
      end
    end
  end

  describe '#short_title_release' do
    context 'if lecture is published' do
      context 'if course is term independent' do
        it 'returns the correct title' do
          course = FactoryBot.build(:course, :term_independent,
                                    title: 'Algebra 1', short_title: 'Alg1')
          lecture = FactoryBot.build(:lecture, :term_independent,
                                     :released_for_all, course: course)
          expect(lecture.short_title_release).to eq 'Alg1'
        end
      end

      context 'if course is not term independent' do
        it 'returns the correct title' do
          I18n.locale = 'de'
          course = FactoryBot.build(:course, title: 'Algebra 1',
                                    short_title: 'Alg1')
          term = FactoryBot.build(:term, season: 'SS', year: 2020)
          lecture = FactoryBot.build(:lecture, :released_for_all,
                                     course: course, term: term)
          expect(lecture.short_title_release).to eq '(V) Alg1 SS 20'
        end
      end
    end

    context 'if lecture is unpublished' do
      context 'if course is term independent' do
        it 'returns the correct title' do
          I18n.locale = 'de'
          course = FactoryBot.build(:course, :term_independent,
                                    title: 'Algebra 1', short_title: 'Alg1')
          lecture = FactoryBot.build(:lecture, :term_independent,
                                     course: course)
          expect(lecture.short_title_release).to eq 'Alg1 (unveröffentlicht)'
        end
      end

      context 'if course is not term independent' do
        it 'returns the correct title' do
          I18n.locale = 'de'
          course = FactoryBot.build(:course, title: 'Algebra 1',
                                    short_title: 'Alg1')
          term = FactoryBot.build(:term, season: 'SS', year: 2020)
          lecture = FactoryBot.build(:lecture, course: course, term: term)
          expect(lecture.short_title_release)
            .to eq '(V) Alg1 SS 20 (unveröffentlicht)'
        end
      end
    end
  end

  describe '#short_title_brackets' do
    context 'if course is term independent' do
      it 'returns the correct title' do
        course = FactoryBot.build(:course, :term_independent,
                                  title: 'Algebra 1', short_title: 'Alg1')
        lecture = FactoryBot.build(:lecture, :term_independent, course: course)
        expect(lecture.short_title_brackets).to eq 'Alg1'
      end
    end

    context 'if course is not term independent' do
      it 'returns the correct title' do
        I18n.locale = 'de'
        course = FactoryBot.build(:course, title: 'Algebra 1',
                                  short_title: 'Alg1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term)
        expect(lecture.short_title_brackets).to eq '(V) Alg1 (SS 20)'
      end
    end
  end

  describe '#title_with_teacher' do
    context 'if no teacher is present' do
      it 'returns the correct title' do
        I18n.locale = 'de'
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term,
                                             teacher: nil)
        expect(lecture.title_with_teacher).to eq '(V) Algebra 1, SS 2020'
      end
    end

    context 'if no teacher name is present' do
      it 'returns the correct title' do
        I18n.locale = 'de'
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term)
        teacher = lecture.teacher
        teacher.name = nil
        expect(lecture.title_with_teacher).to eq '(V) Algebra 1, SS 2020'
      end
    end

    context 'if teacher name is present' do
      it 'returns the correct title' do
        I18n.locale = 'de'
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        teacher = FactoryBot.build(:user, name: 'Harry Bosch')
        lecture = FactoryBot.build(:lecture, course: course, term: term,
                                             teacher: teacher)
        expect(lecture.title_with_teacher)
          .to eq '(V) Algebra 1, SS 2020 (Harry Bosch)'
      end
    end
  end

  describe '#title_with_teacher_no_type' do
    context 'if course is term independent' do
      it 'returns the correct title' do
        course = FactoryBot.build(:course, :term_independent,
                                  title: 'Algebra 1', short_title: 'Alg1')
        teacher = FactoryBot.build(:user, name: 'Harry Bosch')
        lecture = FactoryBot.build(:lecture, :term_independent,
                                   course: course, teacher: teacher)
        expect(lecture.title_with_teacher_no_type)
          .to eq 'Algebra 1, (Harry Bosch)'
      end
    end

    context 'if course is not term independent' do
      it 'returns the correct title' do
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        teacher = FactoryBot.build(:user, name: 'Harry Bosch')
        lecture = FactoryBot.build(:lecture, course: course, term: term,
                                             teacher: teacher)
        expect(lecture.title_with_teacher_no_type)
          .to eq 'Algebra 1, SS 2020 (Harry Bosch)'
      end
    end
  end

  describe '#term_teacher_info' do
    context 'if no teacher is present' do
      it 'returns the correct info' do
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term,
                                             teacher: nil)
        expect(lecture.term_teacher_info).to eq 'SS 2020'
      end
    end

    context 'if no teacher name is present' do
      it 'returns the correct info' do
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        teacher = FactoryBot.build(:user, name: nil)
        lecture = FactoryBot.build(:lecture, course: course, term: term,
                                             teacher: teacher)
        expect(lecture.term_teacher_info).to eq 'SS 2020'
      end
    end

    context 'if no term is present' do
      it 'returns the correct info' do
        course = FactoryBot.build(:course, title: 'Algebra 1')
        teacher = FactoryBot.build(:user, name: 'Harry Bosch')
        lecture = FactoryBot.build(:lecture, course: course, term: nil,
                                             teacher: teacher, sort: 'lecture')
        expect(lecture.term_teacher_info).to eq 'Algebra 1, Harry Bosch'
      end
    end

    context 'if all data are present' do
      it 'returns the corect info' do
        course = FactoryBot.build(:course, title: 'Algebra 1')
        teacher = FactoryBot.build(:user, name: 'Harry Bosch')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term,
                                             teacher: teacher)
        expect(lecture.term_teacher_info).to eq '(V) SS 2020, Harry Bosch'
      end
    end
  end

  describe '#term_teacher_published_info' do
    before :all do
      @course = FactoryBot.build(:course, title: 'Algebra 1')
      @teacher = FactoryBot.build(:user, name: 'Harry Bosch')
      @term = FactoryBot.build(:term, season: 'SS', year: 2020)
    end

    context 'if lecture is published' do
      it 'returns the term_teacher_info' do
        lecture = FactoryBot.build(:lecture, course: @course, term: @term,
                                             teacher: @teacher, released: 'all')
        expect(lecture.term_teacher_published_info)
          .to eq '(V) SS 2020, Harry Bosch'
      end
    end

    context 'if lecture is unpublished' do
      it 'returns the term_teacher_info with an unpublished flag' do
        lecture = FactoryBot.build(:lecture, course: @course, term: @term,
                                             teacher: @teacher, released: nil,
                                             locale: 'de')
        expect(lecture.term_teacher_published_info)
          .to eq '(V) SS 2020, Harry Bosch (unveröffentlicht)'
      end
    end
  end

  describe '#title_term_no_sort' do
    context 'if course is term independent' do
      it 'returns the course title' do
        course = FactoryBot.build(:course, :term_independent,
                                  title: 'Algebra 1', short_title: 'Alg1')
        teacher = FactoryBot.build(:user, name: 'Harry Bosch')
        lecture = FactoryBot.build(:lecture, :term_independent,
                                   course: course, teacher: teacher)
        expect(lecture.title_term_no_sort).to eq 'Algebra 1'
      end
    end

    context 'if course is not term independent' do
      it 'returns the correct title' do
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        teacher = FactoryBot.build(:user, name: 'Harry Bosch')
        lecture = FactoryBot.build(:lecture, course: course, term: term,
                                             teacher: teacher)
        expect(lecture.title_term_no_sort).to eq 'Algebra 1, SS 2020'
      end
    end
  end

  describe '#title_teacher_info' do
    context 'if no teacher is present' do
      it 'returns the correct info' do
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term,
                                             teacher: nil)
        expect(lecture.title_teacher_info).to eq 'Algebra 1'
      end
    end

    context 'if no teacher name is present' do
      it 'returns the correct info' do
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        teacher = FactoryBot.build(:user, name: nil)
        lecture = FactoryBot.build(:lecture, course: course, term: term,
                                             teacher: teacher)
        expect(lecture.title_teacher_info).to eq 'Algebra 1'
      end
    end

    context 'if teacher name is present' do
      it 'returns the correct info' do
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        teacher = FactoryBot.build(:user, name: 'Harry Bosch')
        lecture = FactoryBot.build(:lecture, course: course, term: term,
                                             teacher: teacher)
        expect(lecture.title_teacher_info).to eq '(V) Algebra 1 (Harry Bosch)'
      end
    end
  end

  describe '#locale_with_inheritance' do
    it 'returns the courses locale if no locale is present' do
      course = FactoryBot.build(:course, title: 'Algebra 1', locale: 'pt')
      term = FactoryBot.build(:term, season: 'SS', year: 2020)
      teacher = FactoryBot.build(:user, name: 'Harry Bosch')
      lecture = FactoryBot.build(:lecture, course: course, term: term,
                                           teacher: teacher, locale: nil)
      expect(lecture.locale_with_inheritance).to eq 'pt'
    end

    it 'returns the lectures locale if locale is present' do
      course = FactoryBot.build(:course, title: 'Algebra 1', locale: 'pt')
      term = FactoryBot.build(:term, season: 'SS', year: 2020)
      teacher = FactoryBot.build(:user, name: 'Harry Bosch')
      lecture = FactoryBot.build(:lecture, course: course, term: term,
                                           teacher: teacher, locale: 'br')
      expect(lecture.locale_with_inheritance).to eq 'br'
    end
  end

  describe '#long_title' do
    context 'if course is term independent' do
      it 'returns the correct title' do
        course = FactoryBot.build(:course, :term_independent,
                                  title: 'Algebra 1')
        lecture = FactoryBot.build(:lecture, :term_independent, course: course)
        expect(lecture.long_title).to eq 'Algebra 1'
      end
    end

    context 'if course is not term independent' do
      it 'returns the correct title' do
        I18n.locale = 'de'
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term)
        expect(lecture.long_title).to eq '(V) Algebra 1, SS 2020'
      end
    end
  end

  describe '#card_header' do
    context 'if course is term independent' do
      it 'returns the correct title' do
        course = FactoryBot.build(:course, :term_independent,
                                  title: 'Algebra 1')
        lecture = FactoryBot.build(:lecture, :term_independent, course: course)
        expect(lecture.card_header).to eq 'Algebra 1'
      end
    end

    context 'if course is not term independent' do
      it 'returns the correct title' do
        I18n.locale = 'de'
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term)
        expect(lecture.card_header).to eq '(V) Algebra 1, SS 2020'
      end
    end
  end

  describe '#card_header_path' do
    context 'if lecture is not subscribed' do
      it 'returns nil' do
        course = FactoryBot.build(:course, title: 'Algebra 1')
        term = FactoryBot.build(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.build(:lecture, course: course, term: term)
        user = FactoryBot.build(:user)
        expect(lecture.card_header_path(user)).to be_nil
      end
    end

    context 'if lecture is subscribed' do
      it 'returns the lecture path' do
        course = FactoryBot.create(:course, title: 'Algebra 1')
        term = FactoryBot.create(:term, season: 'SS', year: 2020)
        lecture = FactoryBot.create(:lecture, course: course, term: term)
        user = FactoryBot.build(:user)
        user.lectures << lecture
        expect(lecture.card_header_path(user)).to eq("/lectures/#{lecture.id}")
      end
    end
  end

  describe '#restricted?' do
    it 'returns true if a passphrase is present' do
      lecture = FactoryBot.build(:lecture, passphrase: 'hello')
      expect(lecture.restricted?).to be true
    end

    it 'returns false if no passphrase is present' do
      lecture = FactoryBot.build(:lecture, passphrase: nil)
      expect(lecture.restricted?).to be false
    end
  end

  describe '#visible_for_user?' do
    it 'returns true if user is admin' do
      lecture = FactoryBot.build(:lecture)
      admin = FactoryBot.build(:user, admin: true)
      expect(lecture.visible_for_user?(admin)).to be true
    end

    it 'returns true if user is an editor of the lecture' do
      lecture = FactoryBot.build(:lecture)
      editor = FactoryBot.build(:user)
      lecture.editors << editor
      expect(lecture.visible_for_user?(editor)).to be true
    end

    it 'returns false if user is no admin or editor and lecture is ' \
       'unpublished' do
      lecture = FactoryBot.build(:lecture, released: nil)
      user = FactoryBot.build(:user)
      expect(lecture.visible_for_user?(user)).to be false
    end

    it 'returns false if lecture is restricted and user has not '\
       'subscribed it' do
      lecture = FactoryBot.build(:lecture, passphrase: 'hello')
      user = FactoryBot.build(:user)
      expect(lecture.visible_for_user?(user)).to be false
    end

    it 'returns true if user is generic and lecture is unrestricted' do
      lecture = FactoryBot.build(:lecture, released: 'all')
      user = FactoryBot.build(:user)
      expect(lecture.visible_for_user?(user)).to be true
    end
  end

  context 'tag methods' do
    before :all do
      @lecture = FactoryBot.create(:lecture, :with_toc, released: 'all')
      sections = @lecture.sections
      @tags = FactoryBot.create_list(:tag, 7)
      sections[0].tags = [@tags[1]]
      sections[2].tags = [@tags[1], @tags[2]]
      sections[4].tags = [@tags[3]]
      course = @lecture.course
      course.tags = [@tags[1], @tags[2], @tags[4]]
    end

    describe '#tags' do
      it 'returns all tags associated to sections of the lecture' do
        expect(@lecture.tags).to match_array([@tags[1], @tags[2], @tags[3]])
      end
    end

    describe '#course_tags' do
      it "returns the intersection of lecture's tags and course's tags" do
        expect(@lecture.course_tags).to match_array([@tags[1], @tags[2]])
      end
    end

    describe '#extra_tags' do
      it 'returns lecture tags that are not course tags' do
        expect(@lecture.extra_tags).to match_array([@tags[3]])
      end
    end

    describe '#deferred_tags' do
      it 'returns course tags that are not lecture tags' do
        expect(@lecture.deferred_tags).to match_array([@tags[4]])
      end
    end

    describe '#tags_including_media_tags' do
      it 'returns all tags of lecture and related released media' do
        lesson = FactoryBot.create(:valid_lesson, lecture: @lecture)
        medium1 = FactoryBot.create(:lesson_medium, released: 'all',
                                    prescribed_teachable: lesson)
        medium1.tags = [@tags[1], @tags[5]]
        medium2 = FactoryBot.create(:lesson_medium,
                                    prescribed_teachable: lesson)
        medium2.tags = [@tags[0]]
        medium3 = FactoryBot.create(:lecture_medium, released: 'all',
                                    prescribed_teachable: @lecture)
        medium3.tags = [@tags[1], @tags[6]]
        medium4 = FactoryBot.create(:lecture_medium,
                                    prescribed_teachable: @lecture)
        medium4.tags = [@tags[0]]
        expect(@lecture.tags_including_media_tags)
          .to match_array([@tags[1], @tags[2], @tags[3], @tags[5], @tags[6]])
      end
    end
  end

  # describe '#sections' do
  #   it 'returns the correct sections' do
  #     lecture = FactoryBot.build(:lecture)
  #     first_chapter = FactoryBot.create(:chapter, :with_sections,
  #                                       lecture: lecture)
  #     second_chapter = FactoryBot.create(:chapter, :with_sections,
  #                                        lecture: lecture)
  #     sections = first_chapter.sections + second_chapter.sections
  #     expect(lecture.sections.to_a).to match_array(sections)
  #   end
  # end
  # describe '#short_title' do
  #   it 'returns the correct short_title' do
  #     course = FactoryBot.create(:course, short_title: 'bs')
  #     term =   FactoryBot.create(:term)
  #     lecture = FactoryBot.build(:lecture, course: course, term: term)
  #     expect(lecture.short_title).to eq('bs ' + term.to_label_short)
  #   end
  # end
  # describe '#term_teacher_info' do
  #   it 'returns the correct information' do
  #     term =   FactoryBot.create(:term)
  #     teacher = FactoryBot.create(:user, name: 'Luke Skywalker')
  #     lecture = FactoryBot.build(:lecture, teacher: teacher, term: term)
  #     expect(lecture.term_teacher_info).to eq(term.to_label +
  #                                               ', Luke Skywalker')
  #   end
  # end
  # describe '#description' do
  #   it 'returns the correct description' do
  #     course = FactoryBot.create(:course, title: 'Usual bs')
  #     term =   FactoryBot.create(:term)
  #     lecture = FactoryBot.build(:lecture, course: course, term: term)
  #     expect(lecture.description).to eq({ general: 'Usual bs, ' +
  #                                                     term.to_label })
  #   end
  # end
end
