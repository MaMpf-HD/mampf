# frozen_string_literal: true

# Course class
class Course < ApplicationRecord
  include ApplicationHelper

  has_many :lectures, dependent: :destroy

  # tags are notions that treated in the course
  # e.g.: vector space, linear map are tags for the course 'Linear Algebra 1'
  has_many :course_tag_joins, dependent: :destroy
  has_many :tags,
           through: :course_tag_joins,
           after_remove: :touch_tag,
           after_add: :touch_tag

  has_many :media, -> { order(position: :asc) }, as: :teachable

  # in a course, you can import other media
  has_many :imports, as: :teachable, dependent: :destroy
  has_many :imported_media, through: :imports, source: :medium

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

  # include uploader to realize screenshot upload
  # this makes use of the shrine gem
  include ScreenshotUploader[:image]

  # The next methods coexist for lectures and lessons as well.
  # Therefore, they can be called on any *teachable*

  def course
    self
  end

  alias media_scope course

  def lecture
  end

  def lesson
  end

  def selector_value
    'Course-' + id.to_s
  end

  def to_label
    title
  end

  alias long_title to_label
  alias title_no_term to_label
  alias card_header to_label

  def compact_title
    short_title
  end

  def title_for_viewers
    Rails.cache.fetch("#{cache_key_with_version}/title_for_viewers") do
      short_title
    end
  end

  def locale_with_inheritance
    locale
  end

  def published?
    true
  end

  def card_header_path(user)
  end

  # only irrelevant courses can be deleted
  def irrelevant?
    lectures.empty? && media.empty? && persisted?
  end

  def subscribable_lectures(user)
    return lectures if user.admin || user.in?(editors)
    return lectures.published unless user.edited_lectures.any? || user.teacher?

    lectures.left_outer_joins(:editable_user_joins)
            .where('released IS NOT NULL OR editable_user_joins.user_id = ?'\
                   ' OR teacher_id = ?', user.id, user.id).distinct
  end

  def restricted?
    false
  end

  def lectures_by_date
    lectures.sort
  end

  # returns the array of all tags (sorted by title) together with
  # their ids
  def select_tags_by_title
    tags.map(&:title_id_hash).natural_sort_by { |t| t[:title] }
        .map { |t| [t[:title], t[:id]] }
  end

  # returns all items related to all lectures associated to this course
  def items
    lectures.collect(&:items).flatten
  end

  def subscribed_lectures(user)
    course.lectures & user.lectures
  end

  def to_be_authorized_lectures(user)
    subscribable_lectures(user).restricted - subscribed_lectures(user)
  end

  def subscribed_by?(user)
    user.courses.include?(self)
  end

  def edited_by?(user)
    user.in?(editors)
  end

  def users
    User.where(id: LectureUserJoin.where(lecture: lectures)
                                  .pluck(:user_id).uniq)
  end

  # a course is addable by the user if the user is an editor or teacher of
  # this course or a lecture of this course
  def addable_by?(user)
    in?(user.edited_or_given_courses_with_inheritance)
  end

  alias removable_by? edited_by?

  # returns the ARel of all media that are associated to the course
  # by inheritance (i.e. directly and media which are associated to lectures or
  # lessons associated to this course)
  def media_with_inheritance
    Rails.cache.fetch("#{cache_key_with_version}/media_with_inheritance") do
      Medium.proper.where(teachable: self)
            .or(Medium.proper.where(teachable: lectures))
            .or(Medium.proper.where(teachable: Lesson.where(lecture: lectures)))
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

  # returns the array of titles of courses that can be edited by the given user,
  # together with a string made up of 'Course-' and their id
  # Is used in options_for_select in form helpers.
  def self.editable_selection(user)
    user.editable_courses.pluck(:short_title, :id)
        .natural_sort_by(&:first).map { |c| [c[0], "Course-#{c[1]}"] }
  end

  # returns the array of all tags (sorted by title) together with
  # their ids
  def self.select_by_title
    Course.pluck(:title, :id).natural_sort_by(&:first)
  end

  def questions_w_inheritance
    Question.where(teachable: [self] + [lectures.published],
                   independent: true)
            .locally_visible
  end

  def questions_count
    Rails.cache.fetch("#{cache_key_with_version}/questions_count") do
      questions_w_inheritance.size
    end
  end

  def enough_questions?
    questions_count >= 10
  end

  def create_random_quiz!(tags, count)
    count = 5 unless count.in?([5, 10, 15])
    create_quiz_by_questions!(question_ids_for_quiz(tags, count))
  end

  def question_tags
    tag_ids = MediumTagJoin.where(medium: questions_w_inheritance)
                           .pluck(:tag_id).uniq
    Tag.where(id: tag_ids)
  end

  def question_count(tags)
    questions(tags).count
  end

  def questions(tags)
    return questions_w_inheritance unless tags.any?

    tagged_ids = MediumTagJoin.where(medium: questions_w_inheritance,
                                     tag: tags)
                              .pluck(:medium_id)
                              .uniq
    Question.where(id: tagged_ids)
  end

  def select_question_tags_by_title
    question_tags.map(&:title_id_hash).natural_sort_by { |t| t[:title] }
                 .map { |t| { value: t[:id], text: t[:title] } }
  end

  def image_url_with_host
    return unless image

    image_url(host: host)
  end

  def normalized_image_url_with_host
    return unless image && image(:normalized)

    image_url(:normalized, host: host)
  end

  def image_filename
    return unless image

    image.metadata['filename']
  end

  def image_size
    return unless image

    image.metadata['size']
  end

  def image_resolution
    return unless image

    "#{image.metadata['width']}x#{image.metadata['height']}"
  end

  # returns all titles of courses whose title is close to the given search
  # string wrt to the JaroWinkler metric
  def self.similar_courses(search_string)
    jarowinkler = FuzzyStringMatch::JaroWinkler.create(:pure)
    titles = Course.pluck(:title)
    titles.select do |t|
      jarowinkler.getDistance(t.downcase, search_string.downcase) > 0.8
    end
  end

  private

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

    def create_quiz_by_questions!(question_ids)
      quiz_graph = QuizGraph.build_from_questions(question_ids)
      Quiz.create(description: "#{I18n.t('categories.randomquiz.singular')} "\
                               "#{course.title} #{Time.now}",
                  level: 1,
                  quiz_graph: quiz_graph,
                  sort: 'RandomQuiz',
                  locale: locale)
    end

    def question_ids_for_quiz(tags, count)
      return questions_w_inheritance.pluck(:id).sample(count) unless tags.any?

      tagged_questions = questions(tags)
      question_ids = if tagged_questions.count > count
        QuestionSampler.new(tagged_questions, tags, count).sample!
      else
        tagged_questions.map(&:id).shuffle
      end
    end
end
