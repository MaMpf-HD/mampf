require 'rails_helper'

RSpec.describe Medium, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:medium)).to be_valid
  end
  it 'has a valid factory with tags' do
    expect(FactoryBot.build(:medium, :with_tags)).to be_valid
  end
  it 'has a valid factory with linked media' do
    expect(FactoryBot.build(:medium, :with_linked_media)).to be_valid
  end
  it 'is invalid without a sort' do
    medium = FactoryBot.build(:medium, sort: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid with improper sort' do
    medium = FactoryBot.build(:medium, sort: 'Test')
    expect(medium).to be_invalid
  end
  context 'Question' do
    it 'is invalid if no question_id is given ' do
      medium = FactoryBot.build(:medium, sort: 'Question',
                                          question_id: nil)
      expect(medium).to be_invalid
    end
    it 'is invalid if question_id is duplicate' do
      FactoryBot.create(:medium, sort: 'Question', question_id: 123)
      medium = FactoryBot.build(:medium, sort: 'Question',
                                          question_id: 123)
      expect(medium).to be_invalid
    end
  end
  it 'is invalid without an author' do
    medium = FactoryBot.build(:medium, author: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid without a title' do
    medium = FactoryBot.build(:medium, title: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid with a duplicate title' do
    FactoryBot.create(:medium, title: 'usual bs')
    medium = FactoryBot.build(:medium, title: 'usual bs')
    expect(medium).to be_invalid
  end
  it 'is invalid with empty content' do
    medium = FactoryBot.build(:medium, video_stream_link: nil,
                                        video_file_link: nil,
                                        manuscript_link: nil,
                                        external_reference_link: nil,
                                        sort: 'Kaviar')
    expect(medium).to be_invalid
  end
  it 'is invalid without length if video_stream_link is given' do
    medium = FactoryBot.build(:medium, video_stream_link:
                                         'http://www.test.de/test.mp4',
                                        length: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid without video_size if video_file_link is given' do
    medium = FactoryBot.build(:medium, video_file_link: 'http://www.test.de/test.mp4',
                                       video_size: nil)
    expect(medium).to be_invalid
  end

  it 'is invalid if width is not an integer' do
    medium = FactoryBot.build(:medium, width: 1027.25)
    expect(medium).to be_invalid
  end
  it 'is invalid if width is lower than 100' do
    medium = FactoryBot.build(:medium, width: 99)
    expect(medium).to be_invalid
  end
  it 'is invalid if width is greater than 8192' do
    medium = FactoryBot.build(:medium, width: 8193)
    expect(medium).to be_invalid
  end
  it 'is invalid if height is not an integer' do
    medium = FactoryBot.build(:medium, height: 1027.25)
    expect(medium).to be_invalid
  end
  it 'is invalid if height is lower than 100' do
    medium = FactoryBot.build(:medium, height: 99)
    expect(medium).to be_invalid
  end
  it 'is invalid if height is greater than 4320' do
    medium = FactoryBot.build(:medium, height: 4321)
    expect(medium).to be_invalid
  end
  it 'is invalid if embedded_width is not an integer' do
    medium = FactoryBot.build(:medium, embedded_width: 1027.25)
    expect(medium).to be_invalid
  end
  it 'is invalid if embedded_width is lower than 100' do
    medium = FactoryBot.build(:medium, embedded_width: 99)
    expect(medium).to be_invalid
  end
  it 'is invalid if embedded_width is greater than 8192' do
    medium = FactoryBot.build(:medium, embedded_width: 8193)
    expect(medium).to be_invalid
  end
  it 'is invalid if embedded_height is not an integer' do
    medium = FactoryBot.build(:medium, embedded_height: 1027.25)
    expect(medium).to be_invalid
  end
  it 'is invalid if embedded_height is lower than 100' do
    medium = FactoryBot.build(:medium, embedded_height: 99)
    expect(medium).to be_invalid
  end
  it 'is invalid if embedded_height is greater than 4320' do
    medium = FactoryBot.build(:medium, embedded_height: 4321)
    expect(medium).to be_invalid
  end
  it 'is invalid with nonsense video_size if video_file_link is given' do
    medium = FactoryBot.build(:medium, video_file_link: 'http://www.test.de/test.mp4',
                                        video_size: '1234')
    expect(medium).to be_invalid
  end
  it 'is invalid if length is not a valid expression' do
    medium = FactoryBot.build(:medium, length: '1h77m5s')
    expect(medium).to be_invalid
  end
  it 'is invalid without pages if manuscript_link is given' do
    medium = FactoryBot.build(:medium, manuscript_link: 'http://www.test.de/test.pdf',
                                        pages: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid if pages is not an integer' do
    medium = FactoryBot.build(:medium, pages: 42.25)
    expect(medium).to be_invalid
  end
  it 'is invalid if pages is lower than 1' do
    medium = FactoryBot.build(:medium, pages: 0)
    expect(medium).to be_invalid
  end
  it 'is invalid if pages is greater than 2000' do
    medium = FactoryBot.build(:medium, pages: 2001)
    expect(medium).to be_invalid
  end
  it 'is invalid without manuscript_size if manuscript_link is given' do
    medium = FactoryBot.build(:medium, manuscript_link: 'http://www.test.de/test.pdf',
                                        manuscript_size: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid with nonsense manuscript_size if mansucript_link is given' do
    medium = FactoryBot.build(:medium, video_file_link: 'http://www.test.de/test.pdf',
                                        manuscript_size: '1234')
    expect(medium).to be_invalid
  end
  it 'is invalid without extras_description if extras_link is given' do
    medium = FactoryBot.build(:medium, extras_link: 'http://www.bs.de', extras_description: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid without question_list if sort is Quiz' do
    medium = FactoryBot.build(:medium, sort: 'Quiz', question_list: nil)
    expect(medium).to be_invalid
  end
  it 'is valid if a valid question_list is given and sort is Quiz' do
    medium = FactoryBot.build(:medium, sort: 'Quiz', question_list: '33&775&4')
    expect(medium).to be_valid
  end
  it 'is invalid if an invalid question_list is given and sort is Quiz' do
    medium = FactoryBot.build(:medium, sort: 'Quiz', question_list: 'abc')
    expect(medium).to be_invalid
  end
  it 'is invalid if video_file_link is not a valid http link' do
    medium = FactoryBot.build(:medium, video_file_link: 'aaa')
    expect(medium).to be_invalid
  end
  it 'is invalid if video_stream_link is not a valid http link' do
    medium = FactoryBot.build(:medium, video_stream_link: 'aaa')
    expect(medium).to be_invalid
  end
  it 'is invalid if video_thumbnail_link is not a valid http link' do
    medium = FactoryBot.build(:medium, video_thumbnail_link: 'aaa')
    expect(medium).to be_invalid
  end
  it 'is invalid if manuscript_link is not a valid http link' do
    medium = FactoryBot.build(:medium, manuscript_link: 'aaa')
    expect(medium).to be_invalid
  end
  it 'is invalid if external_reference_link is not a valid http link' do
    medium = FactoryBot.build(:medium, external_reference_link: 'aaa')
    expect(medium).to be_invalid
  end
  it 'is invalid if extras_link is not a valid http link' do
    medium = FactoryBot.build(:medium, extras_link: 'aaa')
    expect(medium).to be_invalid
  end
  context 'callbacks' do
    it 'sets the default sort to Kaviar' do
      medium = Medium.new
      expect(medium.sort).to eq('Kaviar')
    end
    it 'gets assigned default width if video_file_link is given but no width' do
      medium = FactoryBot.create(:medium, video_file_link: 'http://www.test.de/test.mp4',
                                          width: nil)
      expect(medium.width).to eq(DefaultSetting::VIDEO_WIDTH)
    end
    it 'gets assigned default height if video_file_link is given but no height' do
      medium = FactoryBot.create(:medium, video_file_link: 'http://www.test.de/test.mp4',
                                         height: nil)
      expect(medium.height).to eq(DefaultSetting::VIDEO_HEIGHT)
    end
    it 'gets assigned default embedded_width if video_stream_link is given but no embedded_width' do
      medium = FactoryBot.create(:medium, video_stream_link:
                                           'http://www.test.de/test.mp4',
                                         embedded_width: nil)
      expect(medium.embedded_width).to eq(DefaultSetting::EMBEDDED_WIDTH)
    end
    it 'gets assigned default embedded_height if video_stream_link is given but no embedded_height' do
      medium = FactoryBot.create(:medium, video_stream_link:
                                           'http://www.test.de/test.mp4',
                                          embedded_height: nil)
      expect(medium.embedded_height).to eq(DefaultSetting::EMBEDDED_HEIGHT)
    end
    it 'gets assigned default video_player if video_stream_link is given but no video_player' do
      medium = FactoryBot.create(:medium, video_stream_link:
                                           'http://www.test.de/test.mp4',
                                          video_player: nil)
      expect(medium.video_player).to eq(DefaultSetting::VIDEO_PLAYER)
    end
    it 'gets assigned default authoring_software if video_stream_link is given but no authoring_software' do
      medium = FactoryBot.create(:medium, video_stream_link:
                                           'http://www.test.de/test.mp4',
                                          authoring_software: nil)
      expect(medium.authoring_software).to eq(DefaultSetting::AUTHORING_SOFTWARE)
    end
  end
  describe '#search' do
    it 'returns the correct search results' do
      lesson = FactoryBot.create(:lesson)
      course = lesson.course
      kaviar_medium = FactoryBot.create(:medium, teachable: lesson, sort: 'Kaviar')
      sesam_medium = FactoryBot.create(:medium, teachable: lesson.lecture, sort: 'Sesam')
      params = { course_id: course.id.to_s, lecture_id: lesson.lecture.id.to_s, project: 'kaviar'}
      expect(Medium.search(lesson.lecture, params)).to match_array([kaviar_medium])
    end
  end
  describe '#video aspect ratio' do
    it 'returns the correct aspect ratio' do
      medium = FactoryBot.create(:medium, width: 1512, height: 541)
      expect(medium.video_aspect_ratio).to eq(1512.to_f / 541)
    end
  end
  describe '#video_scaled_height' do
    it 'returns the correct scaled height' do
      medium = FactoryBot.create(:medium, width: 1512, height: 541)
      expect(medium.video_scaled_height(2000)).to eq(715)
    end
  end
  describe '#caption' do
    it 'returns the correct caption' do
      lecture = FactoryBot.create(:lecture)
      chapter = FactoryBot.create(:chapter, lecture: lecture)
      first_section = FactoryBot.create(:section, chapter: chapter, title: 'Unsinn')
      second_section = FactoryBot.create(:section, chapter: chapter, title: 'schon wieder')
      lesson = FactoryBot.build(:lesson, lecture: lecture, sections: [first_section, second_section])
      medium = FactoryBot.create(:medium, teachable: lesson, sort: 'Kaviar')
      expect(medium.caption).to eq('Unsinn, schon wieder')
    end
  end
  describe '#tag_titles' do
    it 'returns the correct titles of the tags' do
      first_tag = FactoryBot.create(:tag, title: 'Usual bs')
      second_tag = FactoryBot.create(:tag, title: 'mal wieder')
      medium = FactoryBot.create(:medium, tags: [first_tag, second_tag])
      expect(medium.tag_titles).to eq('Usual bs, mal wieder')
    end
  end
  describe '#card_header' do
    it 'returns the correct header' do
      lesson = FactoryBot.create(:lesson)
      medium = FactoryBot.build(:medium, teachable: lesson)
      expect(medium.card_header).to eq(lesson.lecture.to_label)
    end
  end
  describe '#card_header_teachable_path' do
    it 'returns the correct teachable path' do
      user = FactoryBot.create(:user)
      course = FactoryBot.create(:course)
      lecture = FactoryBot.create(:lecture, course: course)
      lesson = FactoryBot.create(:lesson, lecture: lecture)
      user.courses << course
      user.lectures << lecture
      medium = FactoryBot.create(:medium, teachable: lesson)
      expect(medium.card_header_teachable_path(user))
        .to eq(Rails.application.routes.url_helpers
                    .course_path(course, params: { active: lecture.id }))
    end
  end
  describe '#card_subheader' do
    context 'if medium belongs to a lesson' do
      it 'returns the correct subheader' do
        lesson = FactoryBot.create(:lesson)
        medium = FactoryBot.build(:medium, teachable: lesson, description: nil)
        expect(medium.card_subheader).to eq lesson.title
      end
    end
    context 'if medium does not belong to a lesson' do
      it 'returns the correct subheader' do
        lecture = FactoryBot.create(:lecture)
        medium = FactoryBot.build(:medium, teachable: lecture, description: nil, sort: 'Sesam')
        expect(medium.card_subheader).to eq('SeSAM Video')
      end
    end
  end
  describe '#card_subheader_teachable' do
    it 'returns the correct teachable' do
      user = FactoryBot.create(:user)
      course = FactoryBot.create(:course)
      lecture = FactoryBot.create(:lecture, course: course)
      lesson = FactoryBot.create(:lesson, lecture: lecture)
      user.courses << course
      user.lectures << lecture
      medium = FactoryBot.create(:medium, teachable: lesson, description: nil)
      expect(medium.card_subheader_teachable(user)).to eq(lesson)
    end
  end
  describe '#sort_de' do
    it 'returns the correct sort in german spelling' do
      medium = FactoryBot.build(:medium, sort: 'Question')
      expect(medium.sort_de).to eq('Quiz-Frage')
    end
  end
  describe '#question_ids' do
    it 'retuns the correct question ids' do
      medium = FactoryBot.build(:medium, question_list: '37&259&1002')
      expect(medium.question_ids).to match_array([37,259,1002])
    end
  end
  describe '#teachable_type' do
    it 'returns the correct kind of teachable' do
      lesson = FactoryBot.create(:lesson)
      medium = FactoryBot.build(:medium, teachable: lesson)
      expect(medium.teachable_type).to eq('Lesson')
    end
  end
  describe '#teachable_type_de' do
    it 'returns the correct kind of teachable in german spelling' do
      lesson = FactoryBot.create(:lesson)
      medium = FactoryBot.build(:medium, teachable: lesson)
      expect(medium.teachable_type_de).to eq('Sitzung')
    end
  end
end
