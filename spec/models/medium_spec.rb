require 'rails_helper'

RSpec.describe Medium, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:medium)).to be_valid
  end
  it 'is invalid without a type' do
    medium = FactoryGirl.build(:medium, type: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid with improper type' do
    medium = FactoryGirl.build(:medium, type: 'Test')
    expect(medium).to be_invalid
  end
  it 'is invalid if type is KeksQuestionMedium and no question_id is given ' do
    medium = FactoryGirl.build(:medium, type: 'KeksQuestionMedium',
                                        question_id: nil)
    expect(medium).to be_invalid
  end      
  it 'is invalid without an author' do
    medium = FactoryGirl.build(:medium, author: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid without a title' do
    medium = FactoryGirl.build(:medium, title: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid with empty content' do
    medium = FactoryGirl.build(:medium, video_stream_link: nil,
                                        video_file_link: nil,
                                        manuscript_link: nil,
                                        external_reference_link: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid without width if video_file_link is given' do
    medium = FactoryGirl.build(:medium, video_file_link: 'www.test.de/test.mp4',
                                        width: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid without height if video_file_link is given' do
    medium = FactoryGirl.build(:medium, video_file_link: 'www.test.de/test.mp4',
                                        height: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid without embedded_width if video_stream_link is given' do
    medium = FactoryGirl.build(:medium, video_stream_link:
                                          'www.test.de/test.mp4',
                                        embedded_width: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid without embedded_height if video_stream_link is given' do
    medium = FactoryGirl.build(:medium, video_stream_link:
                                          'www.test.de/test.mp4',
                                        embedded_height: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid without length if video_stream_link is given' do
    medium = FactoryGirl.build(:medium, video_stream_link:
                                          'www.test.de/test.mp4',
                                        length: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid without video_size if video_file_link is given' do
    medium = FactoryGirl.build(:medium, video_file_link: 'www.test.de/test.mp4',
                                        video_size: nil)
    expect(medium).to be_invalid
  end

  it 'is invalid if width is not an integer' do
    medium = FactoryGirl.build(:medium, width: 1027.25)
    expect(medium).to be_invalid
  end
  it 'is invalid if width is lower than 100' do
    medium = FactoryGirl.build(:medium, width: 99)
    expect(medium).to be_invalid
  end
  it 'is invalid if width is greater than 8192' do
    medium = FactoryGirl.build(:medium, width: 8193)
    expect(medium).to be_invalid
  end
  it 'is invalid if height is not an integer' do
    medium = FactoryGirl.build(:medium, height: 1027.25)
    expect(medium).to be_invalid
  end
  it 'is invalid if height is lower than 100' do
    medium = FactoryGirl.build(:medium, height: 99)
    expect(medium).to be_invalid
  end
  it 'is invalid if height is greater than 4320' do
    medium = FactoryGirl.build(:medium, height: 4321)
    expect(medium).to be_invalid
  end
  it 'is invalid if embedded_width is not an integer' do
    medium = FactoryGirl.build(:medium, embedded_width: 1027.25)
    expect(medium).to be_invalid
  end
  it 'is invalid if embedded_width is lower than 100' do
    medium = FactoryGirl.build(:medium, embedded_width: 99)
    expect(medium).to be_invalid
  end
  it 'is invalid if embedded_width is greater than 8192' do
    medium = FactoryGirl.build(:medium, embedded_width: 8193)
    expect(medium).to be_invalid
  end
  it 'is invalid if embedded_height is not an integer' do
    medium = FactoryGirl.build(:medium, embedded_height: 1027.25)
    expect(medium).to be_invalid
  end
  it 'is invalid if embedded_height is lower than 100' do
    medium = FactoryGirl.build(:medium, embedded_height: 99)
    expect(medium).to be_invalid
  end
  it 'is invalid if embedded_height is greater than 4320' do
    medium = FactoryGirl.build(:medium, embedded_height: 4321)
    expect(medium).to be_invalid
  end
  it 'is invalid with nonsense video_size if video_file_link is given' do
    medium = FactoryGirl.build(:medium, video_file_link: 'www.test.de/test.mp4',
                                        video_size: '1234')
    expect(medium).to be_invalid
  end
  it 'is invalid if length is not a valid expression' do
    medium = FactoryGirl.build(:medium, length: '1h77m5s')
    expect(medium).to be_invalid
  end
  it 'is invalid without pages if manuscript_link is given' do
    medium = FactoryGirl.build(:medium, manuscript_link: 'www.test.de/test.pdf',
                                        pages: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid if pages is not an integer' do
    medium = FactoryGirl.build(:medium, pages: 42.25)
    expect(medium).to be_invalid
  end
  it 'is invalid if pages is lower than 1' do
    medium = FactoryGirl.build(:medium, pages: 0)
    expect(medium).to be_invalid
  end
  it 'is invalid if pages is greater than 2000' do
    medium = FactoryGirl.build(:medium, pages: 2001)
    expect(medium).to be_invalid
  end
  it 'is invalid without manuscript_size if manuscript_link is given' do
    medium = FactoryGirl.build(:medium, manuscript_link: 'www.test.de/test.pdf',
                                        manuscript_size: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid with nonsense manuscript_size if mansucript_link is given' do
    medium = FactoryGirl.build(:medium, video_file_link: 'www.test.de/test.pdf',
                                        manuscript_size: '1234')
    expect(medium).to be_invalid
  end
end
