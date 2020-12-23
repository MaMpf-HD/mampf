# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Medium, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:valid_medium)).to be_valid
  end

  # test validations - INCOMPLETE

  it 'is invalid without a sort' do
    medium = FactoryBot.build(:medium, sort: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid with improper sort' do
    medium = FactoryBot.build(:medium, sort: 'Test')
    expect(medium).to be_invalid
  end
  it 'is invalid if external_reference_link is not a valid http link' do
    medium = FactoryBot.build(:medium, external_reference_link: 'aaa')
    expect(medium).to be_invalid
  end

  # test traits and factories

  describe 'with description' do
    it 'has a description' do
      medium = FactoryBot.build(:medium, :with_description)
      expect(medium.description).to be_truthy
    end
  end

  describe 'with editors' do
    it 'has the correct number of editors' do
      medium = FactoryBot.build(:medium, :with_editors, editors_count: 2)
      expect(medium.editors.size).to eq 2
    end
    it 'has one editor when called without editors_count parameter' do
      medium = FactoryBot.build(:medium, :with_editors)
      expect(medium.editors.size).to eq 1
    end
  end

  describe 'with tags' do
    it 'has the correct number of tags' do
      medium = FactoryBot.build(:medium, :with_tags, tags_count: 4)
      expect(medium.tags.size).to eq 4
    end
    it 'has two tags when called without tags_count parameter' do
      medium = FactoryBot.build(:medium, :with_tags)
      expect(medium.tags.size).to eq 2
    end
  end

  describe 'with linked media' do
    it 'has the correct number of linked media' do
      medium = FactoryBot.build(:medium, :with_linked_media,
                                linked_media_count: 3)
      expect(medium.linked_media.size).to eq 3
    end
    it 'has two linked media when called without linked_media_count param' do
      medium = FactoryBot.build(:medium, :with_linked_media)
      expect(medium.linked_media.size).to eq 2
    end
  end

  describe 'with teachable' do
    it 'has an associated lecture if no parameter is given' do
      medium = FactoryBot.build(:medium, :with_teachable)
      expect(medium.teachable).to be_kind_of(Lecture)
    end
    it 'has an associated lesson if teachable_sort param is set to :lesson' do
      medium = FactoryBot.build(:medium, :with_teachable,
                                teachable_sort: :lesson)
      expect(medium.teachable).to be_kind_of(Lesson)
    end
    it 'has an associated course if teachable_sort param is set to :course' do
      medium = FactoryBot.build(:medium, :with_teachable,
                                teachable_sort: :course)
      expect(medium.teachable).to be_kind_of(Course)
    end
  end

  describe 'with manuscript' do
    it 'has a manuscript' do
      medium = FactoryBot.build(:medium, :with_manuscript)
      expect(medium.manuscript).to be_kind_of(PdfUploader::UploadedFile)
    end
  end

  describe 'with video' do
    it 'has a video' do
      medium = FactoryBot.build(:medium, :with_video)
      expect(medium.video).to be_kind_of(VideoUploader::UploadedFile)
    end
  end

  describe 'lesson medium' do
    before :all do
      @medium = FactoryBot.build(:lesson_medium)
    end
    it 'has a valid factory' do
      expect(@medium).to be_valid
    end
    it 'is associated to a lesson' do
      expect(@medium.teachable).to be_kind_of(Lesson)
    end
    it 'has an editor that matches the teacher of the lecture to the lesson' do
      expect(@medium.editors).to include @medium.teachable.lecture.teacher
    end
  end

  describe 'lecture medium' do
    before :all do
      @medium = FactoryBot.build(:lecture_medium)
    end
    it 'has a valid factory' do
      expect(@medium).to be_valid
    end
    it 'is associated to a lecture' do
      expect(@medium.teachable).to be_kind_of(Lecture)
    end
    it 'has an editor that matches the teacher of the lecture' do
      expect(@medium.editors).to include @medium.teachable.teacher
    end
  end

  describe 'course medium' do
    before :all do
      @medium = FactoryBot.build(:course_medium)
    end
    it 'has a valid factory' do
      expect(@medium).to be_valid
    end
    it 'is associated to a course' do
      expect(@medium.teachable).to be_kind_of(Course)
    end
  end


  # test methods - NEEDS TO BE REFACTORED

  # describe '#search' do
  #   it 'returns the correct search results' do
  #     lesson = FactoryBot.create(:lesson)
  #     course = lesson.course
  #     kaviar_medium = FactoryBot.create(:medium, teachable: lesson,
  #                                       sort: 'Kaviar')
  #     sesam_medium = FactoryBot.create(:medium, teachable: lesson.lecture,
  #                                      sort: 'Sesam')
  #     params = { course_id: course.id.to_s,
  #                lecture_id: lesson.lecture.id.to_s, project: 'kaviar'}
  #     expect(Medium.search_all(lesson.lecture, params))
  #       .to match_array([kaviar_medium])
  #   end
  # end

  # describe '#video aspect ratio' do
  #   it 'returns the correct aspect ratio' do
  #     medium = FactoryBot.create(:medium, width: 1512, height: 541)
  #     expect(medium.video_aspect_ratio).to eq(1512.to_f / 541)
  #   end
  # end

  # describe '#video_scaled_height' do
  #   it 'returns the correct scaled height' do
  #     medium = FactoryBot.create(:medium, width: 1512, height: 541)
  #     expect(medium.video_scaled_height(2000)).to eq(715)
  #   end
  # end

  # describe '#caption' do
  #   it 'returns the correct caption' do
  #     lecture = FactoryBot.create(:lecture)
  #     chapter = FactoryBot.create(:chapter, lecture: lecture)
  #     first_section = FactoryBot.create(:section, chapter: chapter,
  #                                       title: 'Unsinn')
  #     second_section = FactoryBot.create(:section, chapter: chapter,
  #                                        title: 'schon wieder')
  #     lesson = FactoryBot.build(:lesson, lecture: lecture,
  #                               sections: [first_section, second_section])
  #     medium = FactoryBot.create(:medium, teachable: lesson, sort: 'Kaviar')
  #     expect(medium.caption).to eq('Unsinn, schon wieder')
  #   end
  # end

  # describe '#tag_titles' do
  #   it 'returns the correct titles of the tags' do
  #     first_tag = FactoryBot.create(:tag, title: 'Usual bs')
  #     second_tag = FactoryBot.create(:tag, title: 'mal wieder')
  #     medium = FactoryBot.create(:medium, tags: [first_tag, second_tag])
  #     expect(medium.tag_titles).to eq('Usual bs, mal wieder')
  #   end
  # end

  # describe '#card_header' do
  #   it 'returns the correct header' do
  #     lesson = FactoryBot.create(:lesson)
  #     medium = FactoryBot.build(:medium, teachable: lesson)
  #     expect(medium.card_header).to eq(lesson.lecture.to_label)
  #   end
  # end

  # describe '#card_header_teachable_path' do
  #   it 'returns the correct teachable path' do
  #     user = FactoryBot.create(:user)
  #     course = FactoryBot.create(:course)
  #     lecture = FactoryBot.create(:lecture, course: course)
  #     lesson = FactoryBot.create(:lesson, lecture: lecture)
  #     user.courses << course
  #     user.lectures << lecture
  #     medium = FactoryBot.create(:medium, teachable: lesson)
  #     expect(medium.card_header_teachable_path(user))
  #       .to eq(Rails.application.routes.url_helpers
  #                   .course_path(course, params: { active: lecture.id }))
  #   end
  # end

  # describe '#card_subheader' do
  #   context 'if medium belongs to a lesson' do
  #     it 'returns the correct subheader' do
  #       lesson = FactoryBot.create(:lesson)
  #       medium = FactoryBot.build(:medium, teachable: lesson,
  #                                 description: nil)
  #       expect(medium.card_subheader).to eq lesson.title
  #     end
  #   end
  #   context 'if medium does not belong to a lesson' do
  #     it 'returns the correct subheader' do
  #       lecture = FactoryBot.create(:lecture)
  #       medium = FactoryBot.build(:medium, teachable: lecture,
  #                                 description: nil, sort: 'Sesam')
  #       expect(medium.card_subheader).to eq('SeSAM Video')
  #     end
  #   end
  # end

  # describe '#card_subheader_teachable' do
  #   it 'returns the correct teachable' do
  #     user = FactoryBot.create(:user)
  #     course = FactoryBot.create(:course)
  #     lecture = FactoryBot.create(:lecture, course: course)
  #     lesson = FactoryBot.create(:lesson, lecture: lecture)
  #     user.courses << course
  #     user.lectures << lecture
  #     medium = FactoryBot.create(:medium, teachable: lesson, description: nil)
  #     expect(medium.card_subheader_teachable(user)).to eq(lesson)
  #   end
  # end

  # describe '#sort_localized' do
  #   it 'returns the correct sort in german spelling' do
  #     medium = FactoryBot.build(:medium, sort: 'Question')
  #     expect(medium.sort_localized).to eq('Quiz-Frage')
  #   end
  # end

  # describe '#question_ids' do
  #   it 'retuns the correct question ids' do
  #     medium = FactoryBot.build(:medium, question_list: '37&259&1002')
  #     expect(medium.question_ids).to match_array([37,259,1002])
  #   end
  # end

  # describe '#teachable_type' do
  #   it 'returns the correct kind of teachable' do
  #     lesson = FactoryBot.create(:lesson)
  #     medium = FactoryBot.build(:medium, teachable: lesson)
  #     expect(medium.teachable_type).to eq('Lesson')
  #   end
  # end

  # describe '#teachable_type_de' do
  #   it 'returns the correct kind of teachable in german spelling' do
  #     lesson = FactoryBot.create(:lesson)
  #     medium = FactoryBot.build(:medium, teachable: lesson)
  #     expect(medium.teachable_type_de).to eq('Sitzung')
  #   end
  # end
end
