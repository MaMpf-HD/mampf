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

  def self.select_by_name
    Medium.all.map { |m| [m.name, m.id] }
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

  def video_width
    return unless video.present?
    video_resolution.split('x')[0].to_i
  end

  def video_height
    return unless video.present?
    video_resolution.split('x')[1].to_i
  end

  def video_aspect_ratio
    return unless video_height != 0 && video_width != 0
    video_width.to_f / video_height
  end

  def video_scaled_height(new_width)
    return unless video_height != 0 && video_width != 0
    (new_width.to_f / video_aspect_ratio).to_i
  end

  def caption
    return description if description.present?
    return unless sort == 'Kaviar' && teachable_sort == 'Lesson'
    teachable.section_titles
  end

  def card_header
    teachable.card_header
  end

  def card_header_teachable_path(user)
    teachable.card_header_path(user)
  end

  def card_subheader
    sort_de
  end

  def sort_de
    { 'Kaviar' => 'KaViaR', 'Sesam' => 'SeSAM',
      'KeksQuestion' => 'Keks-Frage', 'KeksQuiz' => 'Keks-Quiz',
      'Reste' => 'RestE', 'Erdbeere' => 'ErDBeere', 'Kiwi' => 'KIWi' }[sort]
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

  def irrelevant?
    video_stream_link.blank? && video.nil? && manuscript.nil? &&
      external_reference_link.blank? && extras_link.blank?
  end

  def teachable_select
    teachable_type.downcase + '-' + teachable_id.to_s
  end

  def question_id
    return unless sort == 'KeksQuestion'
    external_reference_link.remove(DefaultSetting::KEKS_QUESTION_LINK).to_i
  end

  def question_ids
    return unless sort == 'KeksQuiz'
    external_reference_link.remove(DefaultSetting::KEKS_QUESTION_LINK)
                           .split(',').map(&:to_i)
  end

  def position
    teachable.media.where(sort: self.sort).order(:id).index(self)  + 1
  end

  def siblings
    teachable.media.where(sort: self.sort)
  end

  def ident
    ident = sort_de + '.' + teachable.medium_title
    return ident unless siblings.count > 1
    ident + '.(' + position.to_s + '/' + siblings.count.to_s + ')'
  end

  def details
    return description if description.present?
    return 'Frage ' + question_id.to_s if sort == 'KeksQuestion'
    return 'Fragen ' + question_ids.join(', ') if sort == 'KeksQuiz'
    ''
  end

  def name
    return ident if details.blank?
    ident + '.' + details
  end

  scope :KeksQuestion, -> { where(sort: 'KeksQuestion') }
  scope :Kaviar, -> { where(sort: 'Kaviar') }

  private

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

  def belongs_to_course?(lecture)
    teachable_sort == 'Course' && teachable == lecture.course
  end

  def belongs_to_lecture?(lecture)
    teachable_sort == 'Lecture' && teachable == lecture
  end

  def belongs_to_lesson?(lecture)
    teachable_sort == 'Lesson' && teachable.lecture == lecture
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
