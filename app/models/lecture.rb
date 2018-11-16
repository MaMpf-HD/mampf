# Lecture class
class Lecture < ApplicationRecord
  include ApplicationHelper
  belongs_to :course
  belongs_to :teacher, class_name: 'User', foreign_key: 'teacher_id'
  belongs_to :term
  has_many :chapters, -> { order(position: :asc) }, dependent: :destroy
  has_many :lessons, dependent: :destroy
  has_many :media, as: :teachable
  has_many :lecture_user_joins, dependent: :destroy
  has_many :users, through: :lecture_user_joins
  has_many :editable_user_joins, as: :editable, dependent: :destroy
  has_many :editors, through: :editable_user_joins, as: :editable,
                     source: :user
  validates :course, uniqueness: { scope: [:teacher_id, :term_id],
                                   message: 'Eine Vorlesung mit derselben ' \
                                            'Kombination aus Modul, Semester ' \
                                            'und DozentIn existiert bereits.' }
  after_save :remove_teacher_as_editor

  # The next methods coexist for lectures and lessons as well.
  # Therefore, they can be called on any *teachable*

  def lecture
    self
  end

  def lesson
  end

  def title
    course.title + ', ' + term.to_label
  end

  def to_label
    title
  end

  def compact_title
    course.compact_title + '.' + term.compact_title
  end

  def title_for_viewers
    short_title
  end

  def long_title
    title
  end

  def card_header
    title
  end

  def card_header_path(user)
    return unless user.lectures.include?(self)
    lecture_path
  end

  # specific methods

  def tags
    chapters.includes(sections: :tags).map(&:sections).flatten.collect(&:tags)
            .flatten.uniq
  end

  def course_tags
    tags & course.tags
  end

  def extra_tags
    tags - course.tags
  end

  def deferred_tags
    course.tags - tags
  end

  def items
    chapters.collect { |c| c.sections.includes(:items) }
            .flatten.collect(&:items).flatten
  end

  def media_items_with_inheritance
    media_with_inheritance.collect do |m|
      m.items_with_references.collect { |i| [i[:title_within_lecture], i[:id]] }
    end
                          .reduce(:concat)
  end

  def kaviar?
    Rails.cache.fetch("#{cache_key}/kaviar", expires_in: 2.hours) do
      Medium.where(sort: 'Kaviar').to_a.any? do |m|
        m.teachable.present? && m.teachable.lecture == self
      end
    end
  end

  def short_title
    course.short_title + ' ' + term.to_label_short
  end

  def media_scope
    self
  end

  def short_title_brackets
    course.short_title + ' (' + term.to_label_short + ')'
  end

  def title_with_teacher
    return title unless teacher.present? && teacher.name.present?
    "#{title} (#{teacher.name})"
  end

  def term_teacher_info
    return term.to_label unless teacher.present?
    return term.to_label unless teacher.name.present?
    term.to_label + ', ' + teacher.name
  end

  def title_term_info
    course.title + ', ' + term.to_label
  end

  def title_teacher_info
    return course.title unless teacher.present? && teacher.name.present?
    course.title + ' (' + teacher.name + ')'
  end

  def term_teacher_kaviar_info
    videos = kaviar? ? ' ' : ' nicht '
    term_teacher_info + ' (Vorlesungsvideos' + videos + 'vorhanden)'
  end

  def newest?
    self == course.lectures_by_date.first
  end

  def media_with_inheritance
    Medium.where(id: Medium.includes(:teachable)
                           .select { |m| m.teachable.lecture == self }
                           .map(&:id))
  end

  def sections
    chapters.includes(:sections).collect(&:sections).flatten
  end

  def section_selection
    Rails.cache.fetch("#{cache_key}/section_selection") do
      sections.sort_by(&:calculated_number).map { |s| [s.to_label, s.id] }
    end
  end

  def section_tag_selection
    sections.map do |s|
      { section: s.id, tags: s.tags.map { |t| [t.id, t.title] } }
    end
  end

  def editors_with_inheritance
    ([teacher] + editors.to_a + course.editors).to_a
  end

  def teacher_and_editors_with_inheritance
    ([teacher] + editors_with_inheritance).uniq
  end

  def edited_by?(user)
    return true if editors_with_inheritance.include?(user)
    false
  end

  def primary?(user)
    course_join = CourseUserJoin.where(user: user, course: lecture.course)
    return if course_join.empty?
    course_join.first.primary_lecture_id == id
  end

  def latest?
    course.lectures_by_date.first == self
  end

  def select_chapters
    chapters.order(:position).reverse.map { |c| [c.to_label, c.position] }
  end

  def last_chapter_by_position
    chapters.order(:position).last
  end

  def orphaned_lessons
    lessons.includes(:lesson_section_joins, :sections)
           .select { |l| l.sections.blank? }
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
      m.teachable_type == 'Lesson' && m.teachable.present? &&
        m.teachable.lecture == self
    end
    lecture_results + lesson_results.sort_by { |m| m.teachable.lesson.number }
  end

  def self.sort_by_date(lectures)
    lectures.to_a.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  private

  def lecture_path
    Rails.application.routes.url_helpers
         .course_path(course,
                      params: { active: id })
  end

  def remove_teacher_as_editor
    editors.delete(teacher)
  end
end
