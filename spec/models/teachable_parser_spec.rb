# frozen_string_literal: true

RSpec.describe TeachableParser, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:teachable_parser)).to be_kind_of(TeachableParser)
  end

  describe '#teachables_as_strings' do
    before :all do
      Course.destroy_all
      course1 = FactoryBot.create(:course)
      lecture1 = FactoryBot.create(:lecture, course: course1)
      chapter = FactoryBot.create(:chapter, lecture: lecture1)
      section = FactoryBot.create(:section, chapter: chapter)
      lecture2 = FactoryBot.create(:lecture, course: course1)

      lesson1 = FactoryBot.create(:lesson, :with_lecture_and_date,
                                  lecture: lecture1,
                                  sections: [section])
      FactoryBot.create(:course)
      @course1_str = "Course-#{course1.id}"
      @lecture1_str = "Lecture-#{lecture1.id}"
      @lecture2_str = "Lecture-#{lecture2.id}"
      @lesson1_str = "Lesson-#{lesson1.id}"
    end

    it 'returns [] if :all_teachables flag is set' do
      teachable_parser = FactoryBot.build(:teachable_parser,
                                          all_teachables: '1')
      expect(teachable_parser.teachables_as_strings).to eq([])
    end

    it 'returns the given teachable strings if teachable_inheritance flag'\
       'is not set' do
      teachable_parser = FactoryBot.build(:teachable_parser,
                                          teachable_ids: [@course1_str],
                                          teachable_inheritance: '0')
      expect(teachable_parser.teachables_as_strings)
        .to eq([@course1_str])
    end

    it 'returns inherited teachables as strings if teachable_inheritance'\
       'flag is set (#1)' do
      teachable_parser = FactoryBot.build(:teachable_parser,
                                          teachable_ids: [@course1_str],
                                          teachable_inheritance: '1')
      expect(teachable_parser.teachables_as_strings)
        .to match_array([@course1_str, @lecture1_str, @lecture2_str,
                         @lesson1_str])
    end

    it 'returns all selected lectures and their lessons' do
      teachable_parser = FactoryBot.build(:teachable_parser,
                                          teachable_ids:
                                            [@lecture1_str, @lecture2_str],
                                          teachable_inheritance: '1')
      expect(teachable_parser.teachables_as_strings)
        .to match_array([@lecture1_str, @lecture2_str, @lesson1_str])
    end
  end
end
