# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VttContainer, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:vtt_container)).to be_valid
  end

  # test traits

  describe 'with table of contents' do
    it 'has a table of contents' do
      vtt_container = FactoryBot.build(:vtt_container, :with_table_of_contents)
      expect(vtt_container.table_of_contents)
        .to be_kind_of(VttUploader::UploadedFile)
    end
  end

  describe 'with references' do
    it 'has references' do
      vtt_container = FactoryBot.build(:vtt_container, :with_references)
      expect(vtt_container.references)
        .to be_kind_of(VttUploader::UploadedFile)
    end
  end
end
