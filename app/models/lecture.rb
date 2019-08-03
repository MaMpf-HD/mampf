# Lecture class
class Lecture < ApplicationRecord
  include ApplicationHelper

  belongs_to :course

  # teacher is the user that gives the lecture
  belongs_to :teacher, class_name: 'User', foreign_key: 'teacher_id'

  # a lecture takes place in a certain term
  belongs_to :term

  # a lecture has many chapters, who have positions
  has_many :chapters, -> { order(position: :asc) }, dependent: :destroy

  # during the term, a lot of lessons take place for this lecture
  has_many :lessons, dependent: :destroy,
                     after_add: :touch_siblings,
                     after_remove: :touch_siblings

  # being a teachable (course/lecture/lesson), a lecture has associated media
  has_many :media, as: :teachable

  # a lecture has many users who have subscribed it in their profile
  has_many :lecture_user_joins, dependent: :destroy
  has_many :users, -> { distinct }, through: :lecture_user_joins

  # a lecture has many editors
  # these are users different from the teacher who have the right to
  # modify lecture contents
  has_many :editable_user_joins, as: :editable, dependent: :destroy
  has_many :editors, through: :editable_user_joins, as: :editable,
                     source: :user

  # a lecture has many announcements
  has_many :announcements, dependent: :destroy

  # we do not allow that a teacher gives a certain lecture in a given term
  # of the same sort twice
  validates :course, uniqueness: { scope: [:teacher_id, :term_id, :sort] }

  validates :content_mode, inclusion: { in: ['video', 'manuscript'] }

  # as a teacher has editing rights by definition, we do not need him in the
  # list of editors
  after_save :remove_teacher_as_editor

  # some information about media and lessons are cached
  # to find out whether the cache is out of date, always touch'em after saving
  after_save :touch_media
  after_save :touch_lessons
  after_save :touch_chapters
  after_save :touch_sections

  # scopes for published lectures
  scope :published, -> { where.not(released: nil) }

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

  def selector_value
    'Lecture-' + id.to_s
  end

  def title
    "(#{sort_localized_short}) #{course.title}, #{term.to_label}"
  end

  def to_label
    title
  end

  def compact_title
    "#{sort_localized_short}.#{course.compact_title}.#{term.compact_title}"
  end

  def title_for_viewers
    Rails.cache.fetch("#{cache_key}/title_for_viewers") do
      short_title
    end
  end

  def locale_with_inheritance
    locale || course.locale
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

  def cache_key
    super + '-' + I18n.locale.to_s
  end

  def restricted?
    passphrase.present?
  end

  def visible_for_user?(user)
    return true if user.admin
    return true if edited_by?(user)
    return false unless published?
    return false if restricted? && !self.in?(user.lectures)
    true
  end

  # the next methods deal with the lecture's tags
  # tags are associated to courses, sections, media and lessons
  # in this context, tags associated to courses and to sections are relevant
  # the first ones refer to a kind of top-down-tagging, the second ones
  # refer to a bottom-up-tagging

  # lecture tags are all tags that are associated to sections within chapters
  # associated to the lecture
  def tags
    Rails.cache.fetch("#{cache_key}/tags") do
      chapters.includes(sections: :tags).map(&:sections).flatten.collect(&:tags)
              .flatten.uniq
    end
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

  # returns content items as provided by Script
  # (relevant if content mode is set to manuscript):
  # - disregards equations, exercises and labels without description
  #   and items in quarantine
  def script_items_by_position
    return [] unless manuscript
    Item.where(medium: lecture.manuscript)
        .where.not(sort: 'self')
        .content
        .unquarantined
        .unhidden
        .order(:position)
  end

  def manuscript
    Medium.where(sort: 'Script', teachable: lecture)&.first
  end

  # returns the ARel of all media whose teachable's lecture is the given lecture

  def media_with_inheritance_uncached
    Medium.proper.where(teachable: self)
      .or(Medium.proper.where(teachable: self.lessons))
  end


  def media_with_inheritance
    Rails.cache.fetch("#{cache_key}/media_with_inheritance") do
      media_with_inheritance_uncached
    end
  end

  # returns the array of all items (described by their title and id) which
  # are associated to media associated (with inheritance) to the lecture
  def media_items_with_inheritance
    media_with_inheritance.collect do |m|
      m.items_with_references.collect { |i| [i[:title_within_lecture], i[:id]] }
    end
                          .reduce(:concat)
  end

  def published?
    !released.nil?
  end

  # The next methods return if there are any media in the Kaviar, Sesam etc.
  # projects that are associated to this lecture *with inheritance*
  # These methods make use of caching.

  def kaviar?(user)
    project?('kaviar', user)
  end

  def sesam?(user)
    project?('sesam', user)
  end

  def keks?(user)
    project?('keks', user)
  end

  def erdbeere?(user)
    project?('erdbeere', user)
  end

  def kiwi?(user)
    project?('kiwi', user)
  end

  def nuesse?(user)
    project?('nuesse', user)
  end

  def script?(user)
    project?('script', user)
  end

  def reste?(user)
    project?('reste', user)
  end


  # the next methods put together some information on the lecture (teacher,
  # term, title) in various combinations

  def short_title
    "(#{sort_localized_short}) #{course.short_title} #{term.to_label_short}"
  end

  def short_title_release
    return short_title if published?
    "#{short_title} (#{I18n.t('access.unpublished')})"
  end

  def short_title_brackets
    "(#{sort_localized_short}) #{course.short_title} (#{term.to_label_short})"
  end

  def title_with_teacher
    return title unless teacher.present? && teacher.name.present?
    "#{title} (#{teacher.name})"
  end

  def title_with_teacher_no_type
    "#{course.title}, #{term.to_label} (#{teacher.name})"
  end

  def term_teacher_info
    return term.to_label unless teacher.present?
    return term.to_label unless teacher.name.present?
    "(#{sort_localized_short}) #{term.to_label}, #{teacher.name}"
  end

  def term_teacher_published_info
    return term_teacher_info if published?
    "#{term_teacher_info} (#{I18n.t('access.unpublished')})"
  end

  def title_term_info
    "(#{sort_localized_short}) #{course.title}, #{term.to_label}"
  end

  def title_teacher_info
    return course.title unless teacher.present? && teacher.name.present?
    "(#{sort_localized_short}) #{course.title} (#{teacher.name})"
  end

  def sort_localized
    I18n.t("admin.lecture.#{sort}")
  end

  def sort_localized_short
    I18n.t("admin.lecture.#{sort}_short")
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
    Section.where(chapter: chapters)
  end

  def sections_cached
    Rails.cache.fetch("#{cache_key}/sections") do
      sections.to_a
    end
  end

  # Returns the list of sections of this lecture (by label), together with
  # their ids.
  # Is used in options_for_select in form helpers.
  def section_selection
    Rails.cache.fetch("#{cache_key}/section_selection") do
      sections.natural_sort_by(&:calculated_number)
              .map { |s| [s.to_label, s.id] }
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
    editors.map { |e| [e.info, e.id] }
  end

  # returns the array of lectures that can be edited by the given user,
  # together with a string made up of 'Lecture-' and their id
  # Is used in options_for_select in form helpers.
  def self.editable_selection(user)
    if user.admin?
      return Lecture.sort_by_date(Lecture.includes(:term).all)
                    .map { |l| [l.title_for_viewers, 'Lecture-' + l.id.to_s] }
    end
    Lecture.sort_by_date(Lecture.includes(:course, :editors).all)
           .select { |l| l.edited_by?(user) }
           .map { |l| [l.title_for_viewers, 'Lecture-' + l.id.to_s] }
  end

  # the next methods provide infos on editors and teacher

  def editors_with_inheritance
    ([teacher] + editors.to_a + course.editors).to_a
  end

  # the next methods provide user related information about the lecture

  def edited_by?(user)
    return true if editors_with_inheritance.include?(user) || user == teacher
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
  def path(user)
    return unless user.lectures.include?(self)
    Rails.application.routes.url_helpers
         .lecture_path(self)
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
    lecture_results = filtered_media.where(teachable: self)
    lesson_results = filtered_media.where(teachable:
                                            Lesson.where(lecture: self))
    lecture_results + lesson_results.includes(:teachable)
                                    .sort_by { |m| [m.lesson.date,
                                                    m.lesson.id] }
  end

  def begin_date
    Rails.cache.fetch("#{cache_key}/begin_date") do
      term&.begin_date
    end
  end

  def self.sort_by_date(lectures)
    lectures.sort_by(&:begin_date).reverse
  end

  def forum_title
    "#{title} [#{teacher.name}]"
  end

  def forum?
    Thredded::Messageboard.where(name: forum_title).exists?
  end

  def forum
    Thredded::Messageboard.where(name: forum_title)&.first
  end

  # extract how many posts in the lecture's forum have not been read
  # by the user
  def unread_forum_topics_count(user)
    return unless forum?
    forum_relation = Thredded::Messageboard.where(name: forum_title)
    forum_view =
      Thredded::MessageboardGroupView.grouped(forum_relation,
                                              user: user,
                                              with_unread_topics_counts: true)
    forum_view.first.messageboards.first.unread_topics_count
  end

  # as there is no show action for lessons, this is the path to the show action
  # for courses, with the lecture on top in the carousel
  def lecture_path
    Rails.application.routes.url_helpers
         .lecture_path(self)
  end

  def active_announcements(user)
    user.active_announcements(lecture).map(&:notifiable)
  end

  def self.sorts
    ['lecture', 'seminar', 'proseminar', 'oberseminar']
  end

  def self.sort_localized
    Lecture.sorts.map { |s| [s, I18n.t("admin.lecture.#{s}")] }.to_h
  end

  private

  # used for after save callback
  def remove_teacher_as_editor
    editors.delete(teacher)
  end

  # looks in the cache if there are any media associated *with inheritance*
  # to this lecture and a given project (kaviar, semsam etc.)
  def project_as_user?(project)
    Rails.cache.fetch("#{cache_key}/#{project}") do
      Medium.where(sort: medium_sort[project],
                   released: ['all', 'users', 'subscribers'],
                   teachable: self).exists? ||
      Medium.where(sort: medium_sort[project],
                   released: ['all', 'users', 'subscribers'],
                   teachable: lessons).exists? ||
      Medium.where(sort: medium_sort[project],
                   released: ['all', 'users', 'subscribers'],
                   teachable: course).exists?
    end
  end

  def project?(project, user)
    return project_as_user?(project) unless edited_by?(user)
    course_media = if user.in?(course.editors)
                     Medium.where(sort: medium_sort[project],
                                  teachable: course).exists?
                   else
                      Medium.where(sort: medium_sort[project],
                                   released: ['all', 'users', 'subscribers'],
                                   teachable: course).exists?
                   end
    lecture_media = Medium.where(sort: medium_sort[project],
                                 teachable: self).exists?
    lesson_media = Medium.where(sort: medium_sort[project],
                                teachable: lessons).exists?
    course_media || lecture_media || lesson_media
  end

  def medium_sort
    { 'kaviar' => ['Kaviar'], 'sesam' => ['Sesam'], 'kiwi' => ['Kiwi'],
      'keks' => ['Quiz'], 'nuesse' => ['Nuesse'],
      'erdbeere' => ['Erdbeere'], 'script' => ['Script'], 'reste' => ['Reste']}
  end

  def touch_media
    media_with_inheritance.update_all(updated_at: Time.now)
  end

  def touch_lessons
    lessons.update_all(updated_at: Time.now)
  end

  def touch_siblings(lesson)
    lessons.update_all(updated_at: Time.now)
    Medium.where(teachable: lessons).update_all(updated_at: Time.now)
  end

  def touch_chapters
    chapters.update_all(updated_at: Time.now)
  end

  def touch_sections
    Section.where(chapter: chapters).update_all(updated_at: Time.now)
  end
end
