require 'rails_helper'

RSpec.describe Lecture, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:lecture)).to be_valid
  end
  it 'has a valid factory for including tags' do
    expect(FactoryBot.build(:lecture, :with_disabled_tags)).to be_valid
  end
  it 'is invalid without a term' do
    lecture = FactoryBot.build(:lecture, term: nil)
    expect(lecture).to be_invalid
  end
  it 'is invalid without a teacher' do
    lecture = FactoryBot.build(:lecture, teacher: nil)
    expect(lecture).to be_invalid
  end
  it 'is invalid without a course' do
    lecture = FactoryBot.build(:lecture, course: nil)
    expect(lecture).to be_invalid
  end
  it 'is invalid if duplicate combination of course,teacher and term' do
    course = FactoryBot.create(:course)
    teacher = FactoryBot.create(:user)
    term = FactoryBot.create(:term)
    FactoryBot.create(:lecture, course: course, teacher: teacher, term: term)
    lecture = FactoryBot.build(:lecture, course: course, teacher: teacher,
                                          term: term)
    expect(lecture).to be_invalid
  end
  describe '#tags' do
    it 'returns the correct tags for the lecture' do
      tags = FactoryBot.create_list(:tag, 3)
      course = FactoryBot.create(:course, tags: tags)
      additional_tags = FactoryBot.create_list(:tag, 2)
      disabled_tags = [tags[0], tags[1]]
      lecture = FactoryBot.create(:lecture, course: course,
                                            additional_tags: additional_tags,
                                            disabled_tags: disabled_tags)
      expect(lecture.tags).to match_array([tags[2], additional_tags[0],
                                           additional_tags[1]])
    end
  end
  describe '#sections' do
    it 'returns the correct sections' do
      lecture = FactoryBot.build(:lecture)
      first_chapter = FactoryBot.create(:chapter, :with_sections, lecture: lecture)
      second_chapter = FactoryBot.create(:chapter, :with_sections, lecture: lecture)
      sections = first_chapter.sections + second_chapter.sections
      expect(lecture.sections.to_a).to match_array(sections)
    end
  end
  describe '#to_label' do
    it 'returns the correct label' do
      course = FactoryBot.create(:course, title: 'Usual bs')
      term =   FactoryBot.create(:term)
      lecture = FactoryBot.build(:lecture, course: course, term: term)
      expect(lecture.to_label).to eq('Usual bs, ' + term.to_label)
    end
  end
  describe '#short_title' do
    it 'returns the correct short_title' do
      course = FactoryBot.create(:course, short_title: 'bs')
      term =   FactoryBot.create(:term)
      lecture = FactoryBot.build(:lecture, course: course, term: term)
      expect(lecture.short_title).to eq('bs ' + term.to_label_short)
    end
  end
  describe '#title' do
    it 'returns the correct title' do
      course = FactoryBot.create(:course, title: 'Usual bs')
      term =   FactoryBot.create(:term)
      lecture = FactoryBot.build(:lecture, course: course, term: term)
      expect(lecture.title).to eq('Usual bs, ' + term.to_label)
    end
  end
  describe '#term_teacher_info' do
    it 'returns the correct information' do
      term =   FactoryBot.create(:term)
      teacher = FactoryBot.create(:user, name: 'Luke Skywalker')
      lecture = FactoryBot.build(:lecture, teacher: teacher, term: term)
      expect(lecture.term_teacher_info).to eq(term.to_label + ', Luke Skywalker')
    end
  end
  describe '#description' do
    it 'returns the correct description' do
      course = FactoryBot.create(:course, title: 'Usual bs')
      term =   FactoryBot.create(:term)
      lecture = FactoryBot.build(:lecture, course: course, term: term)
      expect(lecture.description).to eq({ general: 'Usual bs, ' + term.to_label })
    end
  end
end
