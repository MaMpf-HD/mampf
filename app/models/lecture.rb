# Lecture class
class Lecture < ApplicationRecord
  belongs_to :course
  belongs_to :teacher
  belongs_to :term
  has_many :lecture_tag_disabled_joins
  has_many :disabled_tags, through: :lecture_tag_disabled_joins, source: :tag
  has_many :lecture_tag_additional_joins
  has_many :additional_tags, through: :lecture_tag_additional_joins,
                             source: :tag
  has_many :chapters, dependent: :destroy
  has_many :lessons, dependent: :destroy
  has_many :media, as: :teachable
  has_many :lecture_user_joins, dependent: :destroy
  has_many :users, through: :lecture_user_joins
  validates :course, uniqueness: { scope: [:teacher_id, :term_id],
                                   message: 'already exists' }

  def tags
    course_tag_ids = course.tags.pluck(:id)
    disabled_ids = disabled_tags.pluck(:id)
    additional_ids = additional_tags.pluck(:id)
    tag_ids = (course_tag_ids | additional_ids) - disabled_ids
    Tag.where(id: tag_ids)
  end

  def sections
    Section.where(chapter: chapters)
  end

  def kaviar?
    Rails.cache.fetch("#{cache_key}/kaviar", expires_in: 2.hours) do
      Medium.where(sort: 'Kaviar').to_a.any? { |m| m.lecture == self }
    end
  end

  def to_label
    course.title + ', ' + term.to_label
  end

  def short_title
    course.short_title + ' ' + term.to_label_short
  end

  def title
    return 'Vorlesung #' + id.to_s unless course.present? && term.present?
    course.title + ', ' + term.to_label
  end

  def term_teacher_info
    term.to_label + ', ' + teacher.name
  end

  def term_teacher_kaviar_info
    videos = kaviar? ? ' ' : ' nicht '
    term_teacher_info + ' (Vorlesungsvideos' + videos + 'vorhanden)'
  end

  def description
    { general: to_label }
  end

  def newest?
    self == course.lectures_by_date.first
  end

  def lesson
  end

  def lecture
    self
  end

  def primary?(user)
    course_join = CourseUserJoin.where(user: user, course: lecture.course)
    return if course_join.empty?
    course_join.first.primary_lecture_id == id
  end

  def active?(user, preselected_lecture_id)
    if course.subscribed_lectures(user).map(&:id)
             .include?(preselected_lecture_id)
      return id == preselected_lecture_id
    end
    primary?(user)
  end

  def path(user)
    return unless user.lectures.include?(self)
    Rails.application.routes.url_helpers
         .course_path(course, params: { active: id })
  end

  def checked_as_primary_by?(user)
    return primary?(user) if course.subscribed_by?(user)
    false
  end

  def checked_as_secondary_by?(user)
    return false unless course.subscribed_by?(user)
    course.subscribed_lectures(user).include?(self)
  end

  def lecture_lesson_results(filtered_media)
    lecture_results = filtered_media.select { |m| m.teachable == self }
    lesson_results = filtered_media.select do |m|
      m.teachable_type == 'Lesson' && m.lecture == self
    end
    lecture_results + lesson_results.sort_by { |m| m.lesson.number }
  end
end
