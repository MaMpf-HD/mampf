class Talk < ApplicationRecord
  belongs_to :lecture, touch: true

  has_many :speaker_talk_joins, dependent: :destroy
  has_many :speakers, through: :speaker_talk_joins
  validates :title, presence: true

  # being a teachable (course/lecture/lesson), a talk has associated media
  has_many :media, -> { order(position: :asc) }, as: :teachable

  after_save :touch_lecture

  # the talks of a lecture form an ordered list
  acts_as_list scope: :lecture

  def talk
    self
  end

  def lesson
  end

  def to_label
    I18n.t('talk', number: position, title: title)
  end

  def given_by?(user)
    user.in?(speakers)
  end

  def locale_with_inheritance
    lecture.locale_with_inheritance
  end

  def title_for_viewers
    Rails.cache.fetch("#{cache_key_with_version}/title_for_viewers") do
      lecture.title_for_viewers + ', ' + to_label
    end
  end

  def dates_localized
    dates.map { |d| I18n.localize d, format: :concise }.join(', ')
  end

  def locale_with_inheritance
    lecture.locale_with_inheritance
  end

  def locale
    locale_with_inheritance
  end

  def published?
    lecture.published?
  end

  def course
    return unless lecture.present?
    lecture.course
  end

  # a talk should also see other lessons in the same lecture
  def media_scope
    lecture
  end

  def compact_title
    lecture.compact_title + '.V' + position.to_s
  end

  def number
    lecture.talks.index(self) + 1
  end

  def previous
    return unless number > 1
    lecture.talks[number - 2]
  end

  def next
    lecture.talks[number]
  end

  private

  def touch_lecture
    lecture.touch
  end
end
