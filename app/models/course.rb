# Course class
class Course < ApplicationRecord
  include ApplicationHelper
  has_many :lectures, dependent: :destroy

  # tags are notions that treated in the course
  # e.g.: vector space, linear map are tags for the course 'Linear Algebra 1'
  has_many :course_tag_joins, dependent: :destroy
  has_many :tags, through: :course_tag_joins

  has_many :media, as: :teachable

  # users in this context are users who have subscribed to this course
  has_many :course_user_joins, dependent: :destroy
  has_many :users, through: :course_user_joins

  # preceding courses are courses that this course is based upon
  has_many :course_self_joins, dependent: :destroy
  has_many :preceding_courses, through: :course_self_joins

  # editors are users who have the right to modify its content
  has_many :editable_user_joins, as: :editable, dependent: :destroy
  has_many :editors, through: :editable_user_joins, as: :editable,
                     source: :user

  validates :title, presence: { message: 'Titel muss vorhanden sein.' },
                    uniqueness: { message: 'Titel ist bereits vergeben.' }
  validates :short_title,
            presence: { message: 'Kurztitel muss vorhanden sein.' },
            uniqueness: { message: 'Kurztitel ist bereits vergeben.' }

  # The next methods coexist for lectures and lessons as well.
  # Therefore, they can be called on any *teachable*

  def course
    self
  end

  def lecture
  end

  def lesson
  end

  def media_scope
    self
  end

  def selector_value
    'Course-' + id.to_s
  end

  def to_label
    title
  end

  def compact_title
    short_title
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
    return unless user.courses.include?(self)
    course_path
  end

  # only irrelevant courses can be deleted
  def irrelevant?
    lectures.empty? && media.empty? && id.present?
  end

  # The next methods return if there are any media in the Kaviar, Sesam etc.
  # projects that are associated to this course (directly or by inheritance
  # via lecture/lesson).
  # These methods make use of caching.

  def kaviar?
    project?('kaviar')
  end

  def sesam?
    project?('sesam')
  end

  def keks?
    project?('keks')
  end

  def erdbeere?
    project?('erdbeere')
  end

  def kiwi?
    project?('kiwi')
  end

  def nuesse?
    project?('nuesse')
  end

  # returns if there are any media associated to this course
  # which are not of type kaviar
  def available_extras
    hash = { 'sesam' => sesam?, 'keks' => keks?,
             'erdbeere' => erdbeere?, 'kiwi' => kiwi?, 'nuesse' => nuesse? }
    hash.keys.select { |k| hash[k] == true }
  end

  # returns an array with all types of media that are associated to this course
  def available_food
    kaviar_info = kaviar? ? ['kaviar'] : []
    kaviar_info.concat(available_extras)
  end

  def lectures_by_date
    lectures.to_a.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  # extracts hash which describes which modules different from kaviar
  # (i.e. Sesam, Kiwi etc.) the user has subscribed from the user params
  # that are provided to the profile controller, together with the id of
  # the lecture that the user has chosen as primary lecture for this module
  # (that is the one that has the first position in the lectures carousel in
  # the course view)
  # Example:
  # course.extras({"name"=>"John Smith", "course-3"=>"1",
  #  "primary_lecture-3"=>"3", "lecture-3"=>"1", keks-3"=>"1",
  #  "kiwi-3"=>"0", "nuesse-3"=>"1"})
  # {keks?"=>true, "kiwi?"=>false, "nuesse?"=>true,
  #  "primary_lecture_id"=>3}
  def extras(user_params)
    extra_modules = extract_extra_modules(user_params)
    modules = {}
    available_extras.each { |e| modules[e + '?'] = false }
    extra_modules.each { |e| modules[e] = true }
    primary_id = user_params['primary_lecture-' + id.to_s]
    modules['primary_lecture_id'] = primary_id == '0' ? nil : primary_id.to_i
    modules
  end

  # returns all items related to all lectures associated to this course
  def items
    lectures.collect(&:items).flatten
  end

  # returns the lecture which gets to sits on top in the lecture carousel in the
  # lecture view
  def front_lecture(user, active_lecture_id)
    if subscribed_lectures(user).map(&:id).include?(active_lecture_id)
      return Lecture.find(active_lecture_id)
    end
    primary_lecture(user)
  end

  def primary_lecture(user)
    user_join = CourseUserJoin.where(course: self, user: user)
    return if user_join.empty?
    Lecture.find_by_id(user_join.first.primary_lecture_id)
  end

  def subscribed_lectures(user)
    course.lectures & user.lectures
  end

  def subscribed_lectures_by_date(user)
    subscribed_lectures(user).to_a.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  def subscribed_by?(user)
    user.courses.include?(self)
  end

  def edited_by?(user)
    return true if editors.include?(user)
    false
  end

  # returns the ARel of all media that are associated to the course
  # by inheritance (i.e. directly and media which are associated to lectures or
  # lessons associated to this course)
  def media_with_inheritance
    Medium.where(id: Medium.includes(:teachable)
                           .select { |m| m.teachable.course == self }
                           .map(&:id))
  end

  def media_items_with_inheritance
    media_with_inheritance.collect do |m|
      m.items_with_references.collect { |i| [i[:title_within_course], i[:id]] }
    end
                          .reduce(:concat)
  end

  def sections
    lectures.collect(&:sections).flatten
  end

  # returns an array of teachables determined  by the search params
  # search_params is a hash with keys :all_teachables, :teachable_ids
  # teachable ids is an array made up of strings composed of 'lecture-'
  # or 'course-' followed by the id
  # search is done with inheritance
  def self.search_teachables(search_params)
    unless search_params[:all_teachables] == '0'
      return Course.all + Lecture.all + Lesson.all
    end
    courses = Course.where(id: Course.search_course_ids(search_params))
    inherited_lectures = Lecture.where(course: courses)
    selected_lectures = Lecture.where(id: Course
                                            .search_lecture_ids(search_params))
    lectures = (inherited_lectures + selected_lectures).uniq
    lessons = lectures.collect(&:lessons).flatten
    courses + lectures + lessons
  end

  def self.search_lecture_ids(search_params)
    teachable_ids = search_params[:teachable_ids] || []
    teachable_ids.select { |t| t.start_with?('lecture') }
                 .map { |t| t.remove('lecture-') }
  end

  def self.search_course_ids(search_params)
    teachable_ids = search_params[:teachable_ids] || []
    teachable_ids.select { |t| t.start_with?('course') }
                 .map { |t| t.remove('course-') }
  end

  # returns the array of courses that can be edited by the given user,
  # together with a string made up of 'Course-' and their id
  # Is used in options_for_select in form helpers.
  def self.editable_selection(user)
    if user.admin?
      return Course.order(:title)
                   .map { |c| [c.short_title, 'Course-' + c.id.to_s] }
    end
    Course.includes(:editors, :editable_user_joins)
          .order(:title).select { |c| c.edited_by?(user) }
          .map { |c| [c.short_title, 'Course-' + c.id.to_s] }
  end

  private

  # the next two methods are auxiliary methods used in the extras method
  # in order to extract the information on modules subscribed by the user,
  # see the example there
  def filter_keys(user_params)
    user_params.keys.select do |k|
      k.end_with?('-' + id.to_s) && !k.include?('lecture-') &&
        !k.start_with?('course-') && user_params[k] == '1'
    end
  end

  def extract_extra_modules(user_params)
    extra_keys = filter_keys(user_params)
    extra_keys.map { |e| e.remove('-' + id.to_s).concat('?') }
  end

  # looks in the cache if there are any media associated to this course and
  # a given project (kaviar, semsam etc.)
  def project?(project)
    Rails.cache.fetch("#{cache_key}/#{project}") do
      Medium.where(sort: sort[project]).includes(:teachable)
            .any? { |m| m.teachable.present? && m.teachable.course == self }
    end
  end

  def sort
    { 'kaviar' => ['Kaviar'], 'sesam' => ['Sesam'], 'kiwi' => ['Kiwi'],
      'keks' => ['KeksQuiz'], 'nuesse' => ['Nuesse'],
      'erdbeere' => ['Erdbeere'] }
  end

  def course_path
    Rails.application.routes.url_helpers.course_path(self)
  end
end
