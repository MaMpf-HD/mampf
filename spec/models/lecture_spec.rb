# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Lecture, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:lecture)).to be_valid
  end

  # Test validations  -- SOME ARE MISSING

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

  # Test methods -- NEEDS TO BE REFACTORED

  # describe '#tags' do
  #   it 'returns the correct tags for the lecture' do
  #     tags = FactoryBot.create_list(:tag, 3)
  #     course = FactoryBot.create(:course, tags: tags)
  #     additional_tags = FactoryBot.create_list(:tag, 2)
  #     disabled_tags = [tags[0], tags[1]]
  #     lecture = FactoryBot.create(:lecture, course: course,
  #                                           additional_tags: additional_tags,
  #                                           disabled_tags: disabled_tags)
  #     expect(lecture.tags).to match_array([tags[2], additional_tags[0],
  #                                          additional_tags[1]])
  #   end
  # end
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
  # describe '#to_label' do
  #   it 'returns the correct label' do
  #     course = FactoryBot.create(:course, title: 'Usual bs')
  #     term =   FactoryBot.create(:term)
  #     lecture = FactoryBot.build(:lecture, course: course, term: term)
  #     expect(lecture.to_label).to eq('Usual bs, ' + term.to_label)
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
  # describe '#title' do
  #   it 'returns the correct title' do
  #     course = FactoryBot.create(:course, title: 'Usual bs')
  #     term =   FactoryBot.create(:term)
  #     lecture = FactoryBot.build(:lecture, course: course, term: term)
  #     expect(lecture.title).to eq('Usual bs, ' + term.to_label)
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
