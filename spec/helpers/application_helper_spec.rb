require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#full_title' do
    context 'if page_title is not given' do
      it 'returns MaMpf' do
        title = full_title
        expect(title).to eq 'MaMpf'
      end
    end
    context 'if page title is given' do
      it 'returns the correct full title' do
        page_title = [*('A'..'Z')].sample(8).join
        title = full_title(page_title)
        expect(title).to eq 'MaMpf | ' + page_title
      end
    end
  end

  describe '#split_list' do
    before do
      length = rand(50..150)
      @list = Array.new(length){ rand(1..9).to_s}
    end
    context 'if n is not given' do
      it 'splits the list into 4 pieces' do
        expect(split_list(@list).count).to eq(4)
      end
      it 'splits the list into pieces whose join is the original list' do
        expect(split_list(@list).flatten.reject(&:nil?)).to eq(@list)
      end
    end
    context 'if n is given' do
      before do
        @n = rand(2..10)
      end
      it 'splits the list into n pieces' do
        expect(split_list(@list,@n).count).to eq(@n)
      end
      it 'splits the list into pieces whose join is the original list' do
        expect(split_list(@list,@n).flatten.reject(&:nil?)).to eq(@list)
      end
    end
  end

  describe '#filter_tags_by_lectures' do
    it 'returns a correct list of tags' do
      lectures = FactoryBot.create_list(:lecture, 3)
      tags = FactoryBot.create_list(:tag, 2)
      tags[0].additional_lectures = lectures.first(2)
      tags[0].disabled_lectures = [lectures.last]
      tags[1].additional_lectures = lectures.last(2)
      tags[1].disabled_lectures = [lectures.first]
      result = filter_tags_by_lectures(tags,[lectures[2]])
      expect(result).to eq([tags[1]])
    end
  end

  describe '#filter_lectures_by_lectures' do
    it 'returns a correct list of lectures' do
      lectures = FactoryBot.create_list(:lecture, 3)
      filter_lectures = FactoryBot.create_list(:lecture,2).concat(lectures.first(2))
      result = filter_lectures_by_lectures(lectures,filter_lectures)
      expect(result).to eq(lectures.first(2))
    end
  end

  describe '#filter_media_by_lectures' do
    it 'returns a correct list of media' do
      lectures = FactoryBot.create_list(:lecture, 3)
      media = FactoryBot.create_list(:medium, 3)
      media[0].teachable = lectures[0]
      media[1].teachable = lectures[1].course
      media[2].teachable = lectures[2]
      result = filter_media_by_lectures(media,lectures.first(2))
      expect(result).to eq(media.first(2))
    end
  end

end
