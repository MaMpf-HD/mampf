# Medium class
class Medium < ApplicationRecord
  include ApplicationHelper
  belongs_to :teachable, polymorphic: true
  has_many :medium_tag_joins, dependent: :destroy
  has_many :tags, through: :medium_tag_joins
  has_many :links, dependent: :destroy
  has_many :linked_media, through: :links
  has_many :editable_user_joins, as: :editable, dependent: :destroy
  has_many :editors, through: :editable_user_joins, as: :editable,
                     source: :user
  include VideoUploader[:video]
  include ImageUploader[:screenshot]
  include PdfUploader[:manuscript]
  validates :sort, presence: true
  validates :question_id, presence: true, uniqueness: true, if: :keks_question?
  validates :author, presence: true
  validates :title, presence: true, uniqueness: true

  after_initialize :set_defaults
  before_save :fill_in_defaults_for_missing_params
  after_save :touch_teachable

  def self.sort_enum
    %w[Kaviar Erdbeere Sesam Kiwi Reste KeksQuestion KeksQuiz]
  end

  def self.search(primary_lecture, params)
    course = Course.find_by_id(params[:course_id])
    return [] if course.nil?
    filtered = Medium.filter_media(course, params[:project])
    unless params[:lecture_id].present?
      return search_results(filtered, course, primary_lecture)
    end
    lecture = Lecture.find_by_id(params[:lecture_id].to_i)
    return [] unless course.lectures.include?(lecture)
    lecture.lecture_lesson_results(filtered)
  end

  def edited_by?(user)
    return true if user.in?(editors)
    false
  end

  def manuscript_pages
    return unless manuscript.present?
    manuscript[:original].metadata["pages"]
  end

  def screenshot_url
    return unless screenshot.present?
    screenshot.url(host: host)
  end

  def video_url
    return unless video.present?
    video.url(host: host)
  end

  def video_filename
    return unless video.present?
    video.metadata['filename']
  end

  def video_size
    return unless video.present?
    video.metadata['size']
  end

  def video_resolution
    return unless video.present?
    video.metadata['resolution']
  end

  def video_duration
    return unless video.present?
    video.metadata['duration']
  end

  def video_duration_hms_string
    return unless video.present?
    TimeStamp.new(total_seconds: video_duration).hms_string
  end

  def manuscript_url
    return unless manuscript.present?
    manuscript[:original].url(host: host)
  end

  def manuscript_filename
    return unless manuscript.present?
    manuscript[:original].metadata['filename']
  end

  def manuscript_size
    return unless manuscript.present?
    manuscript[:original].metadata['size']
  end

  def manuscript_screenshot_url
    return unless manuscript.present?
    manuscript[:screenshot].url(host: host)
  end

  def video_aspect_ratio
    return unless height != 0 && width != 0
    width.to_f / height
  end

  def video_scaled_height(new_width)
    return unless height != 0 && width != 0
    (new_width.to_f / video_aspect_ratio).to_i
  end

  def caption
    return heading if heading.present?
    return unless sort == 'Kaviar' && teachable_sort == 'Lesson'
    teachable.section_titles
  end

  def tag_titles
    tags.map(&:title).join(', ')
  end

  def card_header
    teachable.description[:general]
  end

  def card_header_teachable_path(user)
    if teachable_sort == 'Course'
      return unless user.courses.include?(teachable)
      return course_path(teachable)
    end
    return unless user.lectures.include?(teachable.lecture)
    lecture_path(teachable)
  end

  def card_subheader
    return description if description.present?
    return subheader_heading unless teachable.description[:specific].present?
    teachable.description[:specific]
  end

  def card_subheader_teachable(user)
    return if description.present? || teachable.description[:specific].nil?
    return unless user.lectures.include?(teachable.lecture)
    teachable
  end

  def sort_de
    { 'Kaviar' => 'KaViaR', 'Sesam' => 'SeSAM',
      'KeksQuestion' => 'Keks-Frage', 'KeksQuiz' => 'Keks-Quiz',
      'Reste' => 'RestE', 'Erdbeere' => 'ErDBeere', 'Kiwi' => 'KIWi' }[sort]
  end

  def question_ids
    return if question_list.nil?
    question_list.split('&').map(&:to_i)
  end

  def teachable_sort
    teachable.class.name
  end

  def teachable_sort_de
    { 'Course' => 'Kurs', 'Lecture' => 'Vorlesung',
      'Lesson' => 'Sitzung' }[teachable_sort]
  end

  def related_to_lecture?(lecture)
    return true if belongs_to_course?(lecture)
    return true if belongs_to_lecture?(lecture)
    return true if belongs_to_lesson?(lecture)
    false
  end

  def related_to_lectures?(lectures)
    lectures.map { |l| related_to_lecture?(l) }.include?(true)
  end

  def course
    return if teachable.nil?
    teachable.course
  end

  def lecture
    return if teachable.nil?
    teachable.lecture
  end

  def lesson
    return if teachable.nil?
    teachable.lesson
  end

  def self.filter_media(course, project)
    return Medium.order(:id) unless project.present?
    return [] unless course.available_food.include?(project)
    sort = project == 'keks' ? 'KeksQuiz' : project.capitalize
    Medium.where(sort: sort).order(:id)
  end

  def self.search_results(filtered_media, course, primary_lecture)
    course_results = filtered_media.select { |m| m.teachable == course }
    primary_results = Medium.filter_primary(filtered_media, primary_lecture)
    secondary_results = Medium.filter_secondary(filtered_media, course)
    secondary_results = secondary_results - course_results - primary_results
    course_results + primary_results + secondary_results
  end

  def self.filter_primary(filtered_media, primary_lecture)
    filtered_media.select do |m|
      m.teachable.present? && m.teachable.lecture == primary_lecture
    end
  end

  def self.filter_secondary(filtered_media, course)
    filtered_media.select do |m|
      m.teachable.present? && m.teachable.course == course
    end
  end

  def relocate_data
    if video_thumbnail_link.present?
      screenshot = open(video_thumbnail_link)
      file = Tempfile.new([title + '-', '.png'])
      file.binmode
      file.write open(screenshot).read
      file.rewind
      file
      self.update(screenshot: file)
    end
    if manuscript_link.present?
      manuscript = open(manuscript_link)
      file = Tempfile.new([title + '-', '.pdf'])
      file.binmode
      file.write open(manuscript).read
      file.rewind
      file
      self.update(manuscript: file)
    end
    if video_file_link.present?
      video = open(video_file_link)
      file = Tempfile.new([title + '-', '.mp4'])
      file.binmode
      file.write open(video).read
      file.rewind
      file
      self.update(video: file)
    end
  end

  def irrelevant?
    video_stream_link.empty? && video.empty? && manuscript.empty? &&
      external_reference_link.empty? && extras_link.empty?
  end

  def teachable_select
    teachable_type.downcase + '-' + teachable_id.to_s
  end

  scope :KeksQuestion, -> { where(sort: 'KeksQuestion') }
  scope :Kaviar, -> { where(sort: 'Kaviar') }

  private

  def set_defaults
    self.sort = 'Kaviar' if new_record?
  end

  def video_content?
    video_stream_link.present? || video_file_link.present?
  end

  def video_content_not_keks_question?
    (video_stream_link.present? || video_file_link.present?) && !keks_question?
  end

  def keks_question?
    sort == 'KeksQuestion'
  end

  def keks_quiz?
    sort == 'KeksQuiz'
  end

  def set_keks_defaults
    self.external_reference_link = external_reference_link.presence ||
                                   (DefaultSetting::KEKS_QUESTION_LINK +
                                    question_id.to_s)
  end

  def fill_in_defaults_for_missing_params
    set_keks_defaults if sort == 'KeksQuestion'
  end

  def touch_teachable
    return if teachable.nil?
    if teachable.course.present? && teachable.course.persisted?
      teachable.course.touch
    end
    optional_touches
  end

  def optional_touches
    if teachable.lecture.present? && teachable.lecture.persisted?
      teachable.lecture.touch
    end
    if teachable.lesson.present? && teachable.lesson.persisted?
      teachable.lesson.touch
    end
  end

  def lecture_path(teachable)
    Rails.application.routes.url_helpers
         .course_path(teachable.course,
                      params: { active: teachable.lecture.id })
  end

  def course_path(teachable)
    Rails.application.routes.url_helpers.course_path(teachable)
  end

  def belongs_to_course?(lecture)
    teachable_sort == 'Course' && teachable == lecture.course
  end

  def belongs_to_lecture?(lecture)
    teachable_sort == 'Lecture' && teachable == lecture
  end

  def belongs_to_lesson?(lecture)
    teachable_sort == 'Lesson' && teachable.lecture == lecture
  end

  def subheader_heading
    { 'KeksQuestion' => 'KeKs Frage Nr. ' + question_id.to_s,
      'KeksQuiz' => 'KeksQuiz', 'Sesam' => 'SeSAM Video',
      'Kiwi' => 'KIWi Video' }[sort]
  end

  def filter_primary(filtered_media, primary_lecture)
    filtered_media.select do |m|
      m.teachable.present? && m.teachable.lecture == primary_lecture
    end
  end

  def filter_secondary(filtered_media, course)
    filtered_media.select do |m|
      m.teachable.present? && m.teachable.course == course
    end
  end
end
