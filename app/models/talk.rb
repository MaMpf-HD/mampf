class Talk < ApplicationRecord
  belongs_to :lecture, touch: true

  has_many :speaker_talk_joins, dependent: :destroy
  has_many :speakers, through: :speaker_talk_joins
  validates :title, presence: true

  # being a teachable (course/lecture/lesson), a talk has associated media
  has_many :media, -> { order(position: :asc) }, as: :teachable

  # a talk has many tags
  has_many :talk_tag_joins, dependent: :destroy
  has_many :tags, through: :talk_tag_joins

  after_save :remove_duplicate_dates
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

  def long_title
    title_for_viewers
  end

  def local_title_for_viewers
    to_label
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

  def card_header
    title_for_viewers
  end

  def card_header_path(user)
    return unless user.lectures.include?(lecture)
    talk_path
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

  def team_info(user)
    return '' unless user.in?(speakers) && (speakers - [user]).any?
    "(#{I18n.t('basics.together_with')} " +
      "#{(speakers - [user]).map(&:tutorial_name).join(', ')})"
  end

  def proper_media
    media.where.not(sort: ['Question', 'Remark'])
  end

  def visible_for_user?(user)
    lecture.visible_for_user?(user)
  end

  private

  def touch_lecture
    lecture.touch
  end

  # path for show talk action
  def talk_path
    Rails.application.routes.url_helpers.talk_path(self)
  end

  def remove_duplicate_dates
    update_columns(dates: dates.uniq)
  end
end
