require 'rails_helper'

RSpec.describe Medium, type: :model do
  it 'has a valid factory' do
    expect(FactoryGirl.build(:medium)).to be_valid
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
  it 'is invalid without video_size if video_file_link is given' do
    medium = FactoryGirl.build(:medium, video_file_link: 'www.test.de/test.mp4',
                                        video_size: nil)
    expect(medium).to be_invalid
  end
  it 'is invalid with nonsense video_size if video_file_link is given' do
    medium = FactoryGirl.build(:medium, video_file_link: 'www.test.de/test.mp4',
                                        video_size: '1234')
    expect(medium).to be_invalid
  end
end
