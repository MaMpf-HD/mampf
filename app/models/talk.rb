class Talk < ApplicationRecord
  belongs_to :lecture, touch: true

  has_many :speaker_talk_joins, dependent: :destroy
  has_many :speakers, through: :speaker_talk_joins
  validates :title, presence: true

  # the talks of a lecture form an ordered list
  acts_as_list scope: :lecture

  def to_label
    I18n.t('talk', number: position, title: title)
  end

  def given_by?(user)
    user.in?(speakers)
  end
end
