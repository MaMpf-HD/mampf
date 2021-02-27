# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MampfMatrix, type: :model do
  it 'has a factory' do
    expect(FactoryBot.build(:medium_publisher)).to be_kind_of(MediumPublisher)
  end

  it 'serializes and deserializes withiut errors' do
    medium = FactoryBot.create(:course_medium)
    publisher = FactoryBot.build(:medium_publisher, medium_id: medium.id)
    medium.publisher = publisher
    medium.save
  end

  describe '#publish!' do
    before :all do
      @medium = FactoryBot.create(:lecture_medium)
      lecture = @medium.teachable
      lecture.update(released: 'all')
      @user = FactoryBot.create(:confirmed_user, email_for_medium: true)
      @medium.editors << @user
      @user.lectures << lecture
      publisher = FactoryBot.build(:medium_publisher,
                                   medium_id: @medium.id,
                                   user_id: @user.id)
      @medium.update(publisher: publisher)
      publisher.publish!
      @medium.reload
    end

    it 'publishes the medium' do
      expect(@medium.released).to eq 'all'
    end

    it 'sets a released_at date' do
      expect(@medium.released_at).not_to be nil
    end

    it 'creates notifications' do
      expect(@user.notifications.size).to eq 1
    end

    it 'publishes the vertices if medium is a quiz and vertices flag is set' do
      medium = FactoryBot.create(:valid_quiz, :with_quiz_graph,
                                 teachable_sort: :lecture)
      lecture = medium.teachable
      lecture.update(released: 'all')
      user = FactoryBot.create(:confirmed_user, email_for_medium: true)
      medium.editors << user
      user.lectures << lecture
      lecture.editors << user
      medium.questions.update_all(teachable_type: 'Lecture',
                                  teachable_id: lecture.id)
      publisher = FactoryBot.build(:medium_publisher,
                                   medium_id: medium.id,
                                   user_id: user.id,
                                   vertices: true)
      medium.update(publisher: publisher)
      publisher.publish!
      expect(medium.questions.map(&:released).uniq).to eq(['all'])
    end

    # TODO: check if an email is sent out sent out
  end
end