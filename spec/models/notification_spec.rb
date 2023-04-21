# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notification, type: :model do
  it 'has a valid factory' do
    expect(FactoryBot.build(:notification)).to be_valid
  end

  # test validations

  it 'is invalid without a recipient' do
    expect(FactoryBot.build(:notification, recipient: nil)).to be_invalid
  end

  # test traits

  describe 'with notifiable' do
    it 'has a notifiable' do
      notification = FactoryBot.build(:notification, :with_notifiable)
      expect(notification.notifiable).not_to be_nil
    end

    it 'has a notifiable of the correct sort' do
      notification = FactoryBot.build(:notification, :with_notifiable,
                                      notifiable_sort: 'Lecture')
      expect(notification.notifiable).to be_kind_of(Lecture)
    end
  end
end
