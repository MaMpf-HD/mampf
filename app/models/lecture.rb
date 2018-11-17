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

  def media_scope
    self
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

  # the next methods deal with the lecture's tags
  # tags are associated to courses, sections, media and lessons
  # in this context, tags associated to courses and to sections are relevant
  # the first ones refer to a kind of top-down-tagging, the second ones
  # refer to a bottom-up-tagging

  # lecture tags are all tags that are associated to sections within chapters
  # associated to the lecture
  def tags
    chapters.includes(sections: :tags).map(&:sections).flatten.collect(&:tags)
            .flatten.uniq
  end

  # course tags are all tags that are lecture tags as well as tags that are
  # associated to the lecture's course
  def course_tags
    tags & course.tags
  end

  # extra tags are tags that are lecture tags but not course tags
  def extra_tags
    tags - course.tags
  end

  # deferred tags are tags that are course tags but not lecture tags
  def deferred_tags
    course.tags - tags
  end

  # lecture items are all items associated to sections within chapters
  # associated to the lecture
  def items
    chapters.collect { |c| c.sections.includes(:items) }
            .flatten.collect(&:items).flatten
  end

  # returns an ARel of all media whose teachable's lecture is the given lecture
  def media_with_inheritance
    Medium.where(id: Medium.includes(:teachable)
                           .select { |m| m.teachable.lecture == self }
                           .map(&:id))
  end

  # returns the array of all items (described by their title and id) which
  # are associated to media associated (with inheritance) to the lecture
  def media_items_with_inheritance
    media_with_inheritance.collect do |m|
      m.items_with_references.collect { |i| [i[:title_within_lecture], i[:id]] }
    end
                          .reduce(:concat)
  end

  # returns whether the lecture has any associated kaviar media
  # (with inheritance)
  def kaviar?
    Rails.cache.fetch("#{cache_key}/kaviar", expires_in: 2.hours) do
      Medium.where(sort: 'Kaviar').to_a.any? do |m|
        m.teachable.present? && m.teachable.lecture == self
      end
    end
  end

  # the next methods pu together some information on the lecture (teacher, term,
  # title) in various combinations

  def short_title
    course.short_title + ' ' + term.to_label_short
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

  # returns whether the lecture is newest among all lectures associated to its
  # course
  def newest?
    self == course.lectures_by_date.first
  end

  def latest?
    course.lectures_by_date.first == self
  end

  # lecture sections are all sections within chapters associated to the lecture
  def sections
    chapters.includes(:sections).collect(&:sections).flatten
  end

  # Returns the list of sections of this lecture (by label), together with
  # their ids.
  # Is used in options_for_select in form helpers.
  def section_selection
    Rails.cache.fetch("#{cache_key}/section_selection") do
      sections.sort_by(&:calculated_number).map { |s| [s.to_label, s.id] }
    end
  end

  # Returns a hash of sections and associated tags (by label and id)
  def section_tag_selection
    sections.map do |s|
      { section: s.id, tags: s.tags.map { |t| [t.id, t.title] } }
    end
  end

  # Returns the list of chapters of this lecture (by label), together with
  # their ids.
  # Is used in options_for_select in form helpers.
  def select_chapters
    chapters.order(:position).reverse.map { |c| [c.to_label, c.position] }
  end

  # Returns the list of editors of this lecture (by info), together with
  # their ids.
  # Is used in options_for_select in form helpers
  def select_editors
    editors.map { |e| [e.info, e.id]}
  end

  # the next methods provide infos on editors and teacher

  def editors_with_inheritance
    ([teacher] + editors.to_a + course.editors).to_a
  end

  def teacher_and_editors_with_inheritance
    ([teacher] + editors_with_inheritance).uniq
  end

  # the next methods provide user related information about the lecture

  def edited_by?(user)
    return true if editors_with_inheritance.include?(user)
    false
  end

  # is it the user's chosen primary lecture among the course's lectures?
  # returns nil if course is not subscribed
  def primary?(user)
    course_join = CourseUserJoin.where(user: user, course: lecture.course)
    return if course_join.empty?
    course_join.first.primary_lecture_id == id
  end

  # is it the user's chosen primary lecture among the course's lectures?
  def checked_as_primary_by?(user)
    return primary?(user) if course.subscribed_by?(user)
    false
  end

  # is it one of the user's chosen secondary lecture among the
  # course's lectures?
  def checked_as_secondary_by?(user)
    return false unless course.subscribed_by?(user)
    course.subscribed_lectures(user).include?(self)
  end

  # returns true if
  # - this lecture coincides with the given preselected lecture, and the
  #   preselected lecture is subscribed by the user
  # OR
  # - this lecture is the user's primary lecture for this course
  def active?(user, preselected_lecture_id)
    if course.subscribed_lectures(user).map(&:id)
             .include?(preselected_lecture_id)
      return id == preselected_lecture_id
    end
    primary?(user)
  end

  # returns path for show action of the lecture's course,
  # with the lecture on top of the lecture carousel (if subscribed by user)
  def path(user)
    return unless user.lectures.include?(self)
    Rails.application.routes.url_helpers
         .course_path(course, params: { active: id })
  end

  def last_chapter_by_position
    chapters.order(:position).last
  end

  # an orphaned lesson is a lesson in this lecture which has no sections
  # actually, the existence of something like that should be prevented
  # by the GUI
  def orphaned_lessons
    lessons.includes(:lesson_section_joins, :sections)
           .select { |l| l.sections.blank? }
  end

  # for a given list of media, sorts them as follows:
  # 1) media associated to the lecture
  # 2) media associated to lessons of the lecture, sorted by lesson numbers
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

  # used for after save callback
  def remove_teacher_as_editor
    editors.delete(teacher)
  end
end
