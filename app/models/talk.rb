# Talk class
class Talk < ApplicationRecord
  include Registration::Registerable
  include Rosters::Rosterable
  include Assessment::Assessable

  belongs_to :lecture, touch: true

  before_save :remove_duplicate_dates
  after_create :setup_assessment, if: -> { Flipper.enabled?(:assessment_grading) }

  has_many :speaker_talk_joins, dependent: :destroy
  has_many :speakers, through: :speaker_talk_joins
  # Alias for Rosterable compatibility (enables efficient SQL joins in Campaign#unassigned_users)
  has_many :members, through: :speaker_talk_joins, source: :speaker

  has_many :claims, as: :claimable, dependent: :destroy

  validates :title, presence: true
  validate :lecture_must_be_seminar

  # being a teachable (course/lecture/lesson), a talk has associated media
  has_many :media, -> { order(position: :asc) }, as: :teachable,
                                                 dependent: :destroy,
                                                 inverse_of: :teachable

  # a talk has many tags
  has_many :talk_tag_joins, dependent: :destroy
  has_many :tags, through: :talk_tag_joins

  after_save :touch_lecture

  # the talks of a lecture form an ordered list
  acts_as_list scope: :lecture

  delegate :locale_with_inheritance, :published?, :visible_for_user?, :course,
           to: :lecture

  def talk
    self
  end

  def lesson
  end

  def to_label
    I18n.t("talk", number: position, title: title)
  end

  def to_label_with_speakers
    return to_label unless speakers.any?

    "#{to_label} (#{speakers.map(&:tutorial_name).join(", ")})"
  end

  def registration_title
    to_label_with_speakers
  end

  def long_title
    title_for_viewers
  end

  def local_title_for_viewers
    to_label
  end

  def short_title_with_lecture_date
    title_for_viewers
  end

  def given_by?(user)
    user.in?(speakers)
  end

  def title_for_viewers
    Rails.cache.fetch("#{cache_key_with_version}/title_for_viewers") do
      "#{lecture.title_for_viewers}, #{to_label}"
    end
  end

  def card_header
    title_for_viewers
  end

  def card_header_path(user)
    return unless user.lectures.include?(lecture)

    talk_path
  end

  def locale
    locale_with_inheritance
  end

  # a talk should also see other lessons in the same lecture
  def media_scope
    lecture
  end

  def compact_title
    "#{lecture.compact_title}.V#{position}"
  end

  def number
    position
  end

  def previous
    higher_item
  end

  def next
    lower_item
  end

  def proper_media
    media.where.not(sort: ["Question", "Remark"])
  end

  def editors_with_inheritance
    (speakers + lecture.editors_with_inheritance).uniq
  end

  def add_speaker(speaker)
    speakers << speaker unless speaker.in?(speakers)
  end

  def roster_entries
    speaker_talk_joins
  end

  def roster_user_id_column
    :speaker_id
  end

  def roster_association_name
    :speaker_talk_joins
  end

  def seed_participations_from_roster!
    return unless assessment

    # Talk roster = speakers
    user_ids = speakers.pluck(:id)

    assessment.seed_participations_from!(
      user_ids: user_ids,
      tutorial_mapping: {}
    )
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
      dates.uniq! # TODO: replace dates array by a set to avoid this
    end

    def lecture_must_be_seminar
      return unless lecture
      return if lecture.seminar?

      errors.add(:lecture, :must_be_seminar)
    end

    def setup_assessment
      ensure_assessment!(
        requires_points: false,
        requires_submission: false
      )
      seed_participations_from_roster!
    end
end
