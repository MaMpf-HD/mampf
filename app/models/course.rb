# Course class
class Course < ApplicationRecord
  include ApplicationHelper

  has_many :lectures, dependent: :destroy

  # tags are notions that treated in the course
  # e.g.: vector space, linear map are tags for the course 'Linear Algebra 1'
  has_many :course_tag_joins, dependent: :destroy
  has_many :tags, through: :course_tag_joins,
           after_remove: :touch_tag,
           after_add: :touch_tag

  has_many :media, -> { order(position: :asc) }, as: :teachable

  # in a course, you can import other media
  has_many :imports, as: :teachable, dependent: :destroy
  has_many :imported_media, through: :imports, source: :medium

  # users in this context are users who have subscribed to this course
  has_many :course_user_joins, dependent: :destroy
  has_many :users, -> { distinct }, through: :course_user_joins

  # preceding courses are courses that this course is based upon
  has_many :course_self_joins, dependent: :destroy
  has_many :preceding_courses, through: :course_self_joins

  # editors are users who have the right to modify its content
  has_many :editable_user_joins, as: :editable, dependent: :destroy
  has_many :editors, through: :editable_user_joins, as: :editable,
                     source: :user

  # a course has many divisions of study programs,
  # e.g. "BSc Math (100%) Wahlpflichtbereich 1"
  # and "BSc Math (50%) Pflichtmodule"
  has_many :division_course_joins, dependent: :destroy
  has_many :divisions, through: :division_course_joins


  validates :title, presence: true, uniqueness: true
  validates :short_title, presence: true, uniqueness: true

  # some information about media and lectures are cached
  # to find out whether the cache is out of date, always touch'em after saving
  after_save :touch_media
  after_save :touch_lectures_and_lessons

  # if the course is destroyed, its forum (if existent) should be destroyed
  # as well
  before_destroy :destroy_forum

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
    Rails.cache.fetch("#{cache_key_with_version}/title_for_viewers") do
      short_title
    end
  end

  def long_title
    title
  end

  def locale_with_inheritance
    locale
  end

  def card_header
    title
  end

  def published?
    true
  end

  def card_header_path(user)
    return unless user.courses.include?(self)
    course_path
  end

  # only irrelevant courses can be deleted
  def irrelevant?
    lectures.empty? && media.empty? && id.present?
  end

  def published_lectures
    lectures.published
  end

  def subscribable_lectures(user)
    return lectures if user.admin
    return published_lectures unless user.editor? || user.teacher?
    lectures.where(id: lectures.select { |l| l.edited_by?(user) ||
                                               l.published? }
                               .map(&:id))
  end

  def subscribable_lectures_by_date(user)
    subscribable_lectures(user).to_a.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  def restricted?
    false
  end

  # The next methods return if there are any media in the Kaviar, Sesam etc.
  # projects that are associated to this course *without inheritance*
  # These methods make use of caching.

  def kaviar?(user)
    project?('kaviar',user)
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

  def lectures_by_date
    lectures.to_a.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  def published_lectures_by_date
    published_lectures.to_a.sort do |i, j|
      j.term.begin_date <=> i.term.begin_date
    end
  end

  # returns the array of all tags (sorted by title) together with
  # their ids
  def select_tags_by_title
    tags.map { |t| t.title_id_hash }
        .natural_sort_by { |t| t[:title] }
        .map { |t| [t[:title], t[:id]] }
  end

  # extracts  the id of the lecture that the user has chosen as
  # primary lecture for this module
  # (that is the one that has the first position in the lectures carousel in
  # the course view)
  # Example:
  # course.extras({"name"=>"John Smith", "course-3"=>"1",
  #  "primary_lecture-3"=>"3", "lecture-3"=>"1"})
  # {"primary_lecture_id"=>3}
  def extras(user_params)
    modules = {}
    primary_id = user_params['primary_lecture-' + id.to_s]
    modules['primary_lecture_id'] = primary_id.to_i.zero? ? nil : primary_id.to_i
    modules
  end

  # returns all items related to all lectures associated to this course
  def items
    lectures.collect(&:items).flatten
  end

  def primary_lecture(user, eagerload: false)
    user_join = CourseUserJoin.where(course: self, user: user)
    return unless user_join.any?
    unless eagerload
      return Lecture.find_by_id(user_join.first.primary_lecture_id)
    end
    Lecture.includes(:teacher, :term, :editors, :users,
                     :announcements, :imported_media,
                     course: [:editors],
                     media: [:teachable, :tags],
                     lessons: [media: [:tags]],
                     chapters: [:lecture,
                                sections: [lessons: [:tags],
                                           chapter: [:lecture],
                                           tags: [:notions, :lessons]]])
           .find_by_id(user_join.first.primary_lecture_id)
  end

  def subscribed_lectures(user)
    course.lectures & user.lectures
  end

  def to_be_authorized_lectures(user)
    subscribable_lectures(user).select(&:restricted?) -
      subscribed_lectures(user)
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

  # a course is addable by the user if the user is an editor or teacher of
  # this course or a lecture of this course
  def addable_by?(user)
    in?(user.edited_or_given_courses_with_inheritance)
  end

  # a course is removable by the user if the user is an editor of this course
  def removable_by?(user)
    in?(user.edited_courses)
  end

  # returns the ARel of all media that are associated to the course
  # by inheritance (i.e. directly and media which are associated to lectures or
  # lessons associated to this course)
  def media_with_inheritance
    Rails.cache.fetch("#{cache_key_with_version}/media_with_inheritance") do
      Medium.proper.where(teachable: self)
        .or(Medium.proper.where(teachable: self.lectures))
        .or(Medium.proper.where(teachable: Lesson.where(lecture: self.lectures)))
    end
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
    if search_params[:all_teachables] == '1'
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
    teachable_ids.select { |t| t.start_with?('Lecture') }
                 .map { |t| t.remove('Lecture-') }
  end

  def self.search_course_ids(search_params)
    teachable_ids = search_params[:teachable_ids] || []
    teachable_ids.select { |t| t.start_with?('Course') }
                 .map { |t| t.remove('Course-') }
  end

  def self.search_inherited_teachables(search_params)
    return unless search_params[:teachable_ids]
    self.search_teachables(search_params).map { |t| "#{t.class}-#{t.id}" }
  end

  # returns the array of courses that can be edited by the given user,
  # together with a string made up of 'Course-' and their id
  # Is used in options_for_select in form helpers.
  def self.editable_selection(user)
    if user.admin?
      return Course.order(:title)
                   .map { |c| [c.title_for_viewers, 'Course-' + c.id.to_s] }
    end
    Course.includes(:editors, :editable_user_joins)
          .order(:title).select { |c| c.edited_by?(user) }
          .map { |c| [c.title_for_viewers, 'Course-' + c.id.to_s] }
  end

  # returns the array of all tags (sorted by title) together with
  # their ids
  def self.select_by_title
    Course.all.to_a.natural_sort_by(&:title).map { |t| [t.title, t.id] }
  end

  def questions_count
    Rails.cache.fetch("#{cache_key_with_version}/questions_count") do
      Question.where(teachable: [self] + [lectures.published],
                     independent: true,
                     released: ['all', 'users'])
              .pluck(:id).count
    end
  end

  def enough_questions?
    questions_count >= 10
  end

  def create_random_quiz!(tags, count)
    count = 5 unless count.in?([5,10,15])
    if tags.any?
      tagged_questions = questions(tags)
      if tagged_questions.count > count
        # we use the following algorithm for one-pass weighted sampling:
        # http://utopia.duth.gr/~pefraimi/research/data/2007EncOfAlg.pdf
        # see also https://gist.github.com/O-I/3e0654509dd8057b539a
        weighted_questions = weighted_question_ids(tagged_questions, tags)
        sample = weighted_questions.max_by(count) do
          |_, weight| rand ** (1.0 / weight)
        end
        question_ids = sample.map(&:first)
      else
        question_ids = tagged_questions.map(&:id).shuffle
      end
    else
      question_ids = questions_with_inheritance.pluck(:id).sample(count)
    end
    quiz_graph = QuizGraph.build_from_questions(question_ids)
    quiz = Quiz.new(description: "#{I18n.t('categories.randomquiz.singular')} #{course.title} #{Time.now}",
                    level: 1,
                    quiz_graph: quiz_graph,
                    sort: 'RandomQuiz',
                    locale: locale)
    quiz.save
    return quiz.errors unless quiz.valid?
    quiz
  end

  def question_tags
    tag_ids = MediumTagJoin.where(medium: questions_with_inheritance)
                           .pluck(:tag_id).uniq
    Tag.where(id: tag_ids)
  end

  def questions_with_inheritance
    Question.where(teachable: [self] + [lectures.published],
                   independent: true)
            .locally_visible
  end

  def question_count(tags)
    questions(tags).count
  end

  def weighted_question_ids(questions, tags)
    tag_ids = tags.pluck(:id)
    weighted_questions = questions(tags).includes(:tags).map do |q|
      [q.id, (q.tag_ids & tag_ids).count]
    end
    weighted_questions.to_h
  end

  def questions(tags)
    return questions_with_inheritance unless tags.any?
    tagged_ids = MediumTagJoin.where(medium: questions_with_inheritance,
                                     tag: tags)
                              .pluck(:medium_id)
                              .uniq
    Question.where(id: tagged_ids)
  end

  def select_question_tags_by_title
    question_tags.map { |t| t.title_id_hash }
                 .natural_sort_by { |t| t[:title] }
                 .map { |t| { value: t[:id], text: t[:title] } }
  end

  def forum_title
    "#{title} [#{I18n.t('basics.course')}]"
  end

  def forum?
    forum_id.present?
  end

  def forum
    Thredded::Messageboard.find_by_id(forum_id)
  end

  # extract how many posts in the course's forum have not been read
  # by the user
  def unread_forum_topics_count(user)
    return unless forum?
    forum_relation = Thredded::Messageboard.where(id: forum_id)
    forum_view =
      Thredded::MessageboardGroupView.grouped(forum_relation,
                                              user: user,
                                              with_unread_topics_counts: true)
    forum_view.first.messageboards.first.unread_topics_count
  end

  private

  # looks in the cache if there are any media associated *without_inheritance*
  # to this course and a given project (kaviar, sesam etc.)
  def project_as_user?(project)
    Rails.cache.fetch("#{cache_key_with_version}/#{project}") do
      Medium.where(sort: sort[project],
                   released: ['all', 'users', 'subscribers'],
                   teachable: self).exists?
    end
  end

  def project?(project, user)
    return project_as_user?(project) unless edited_by?(user)
    Medium.where(sort: sort[project],
                 teachable: self).exists?
  end

  def sort
    { 'kaviar' => ['Kaviar'], 'sesam' => ['Sesam'], 'kiwi' => ['Kiwi'],
      'keks' => ['Quiz'], 'nuesse' => ['Nuesse'],
      'erdbeere' => ['Erdbeere'], 'script' => ['Script'], 'reste' => ['Reste'] }
  end

  def course_path
    Rails.application.routes.url_helpers.course_path(self)
  end

  def touch_media
    media_with_inheritance.update_all(updated_at: Time.now)
  end

  def touch_tag(tag)
    tag.touch
    Sunspot.index! tag
  end

  def touch_lectures_and_lessons
    lectures.update_all(updated_at: Time.now)
    Lesson.where(lecture: lectures).update_all(updated_at: Time.now)
  end

  def destroy_forum
    return unless forum
    forum.destroy
  end
end
