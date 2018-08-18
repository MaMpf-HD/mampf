# Medium class
class Medium < ApplicationRecord
  belongs_to :teachable, polymorphic: true, optional: true
  has_many :medium_tag_joins
  has_many :tags, through: :medium_tag_joins
  has_many :links, dependent: :destroy
  has_many :linked_media, through: :links
  validates :sort, presence: true,
                   inclusion: { in: :sort_enum }
  validates :question_id, presence: true, uniqueness: true, if: :keks_question?
  validates :author, presence: true
  validates :title, presence: true, uniqueness: true
  validate :nonempty_content?
  validates :video_file_link, http_url: true, if: :video_file_link?
  validates :video_thumbnail_link, http_url: true,
                                   if: :video_content_not_keks_question?
  validates :video_stream_link, http_url: true, if: :video_stream_link?
  validates :manuscript_link, http_url: true, if: :manuscript_link?
  validates :external_reference_link, http_url: true,
                                      if: :external_reference_link?
  validates :extras_link, http_url: true, if: :extras_link?
  validates :width, numericality: { only_integer: true,
                                    greater_than_or_equal_to: 100,
                                    less_than_or_equal_to: 8192 },
                    if: :width?
  validates :height, numericality: { only_integer: true,
                                     greater_than_or_equal_to: 100,
                                     less_than_or_equal_to: 4320 },
                     if: :height?
  validates :embedded_width, numericality: { only_integer: true,
                                             greater_than_or_equal_to: 100,
                                             less_than_or_equal_to: 8192 },
                             if: :embedded_width?
  validates :embedded_height, numericality: { only_integer: true,
                                              greater_than_or_equal_to: 100,
                                              less_than_or_equal_to: 4320 },
                              if: :embedded_height?
  validates :length, presence: true,
                     format: { with: /\A[0-9]h[0-5][0-9]m[0-5][0-9]s\z/ },
                     if: :video_content?

  # video_size, manuscript_size are in a format compatible with 'filesize' gem
  validates :video_size, presence: true,
                         format:
                           { with: /\A([\d,.]+)?\s?(?:([kmgtpezy])i)?b\z/i },
                         if: :video_file_link?
  validates :pages, presence: true,
                    numericality: { only_integer: true,
                                    greater_than_or_equal_to: 1,
                                    less_than_or_equal_to: 2000 },
                    if: :manuscript_link?
  validates :manuscript_size, presence: true,
                              format:
                                { with: /\A([\d,.]+)?\s?(?:([kmgtpezy])i)?b\z/i },
                              if: :manuscript_link?
  validates :question_list, presence: true,
                            format: { with: /\A(\d+&)*\d+\z/ },
                            if: :keks_quiz?
  validates :extras_description, presence: true, if: :extras_link?

  after_initialize :set_defaults
  before_save :fill_in_defaults_for_missing_params
  def sort_enum
    %w[Kaviar Erdbeere Sesam Kiwi Reste KeksQuestion KeksQuiz]
  end
  after_save :touch_teachable

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
    primary_results = filtered_media.select do |m|
      m.teachable.present? && m.teachable.lecture == primary_lecture
    end
    secondary_results = filtered_media.select do |m|
      m.teachable.present? && m.teachable.course == course
    end
    secondary_results = secondary_results - course_results - primary_results
    course_results + primary_results + secondary_results
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

  def nonempty_content?
    return true if video_stream_link.present? ||
                   video_file_link.present? ||
                   manuscript_link.present? ||
                   external_reference_link.present? ||
                   keks_question?
    errors.add(:base, 'empty content')
    false
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

  def set_video_defaults
    self.width ||= DefaultSetting::VIDEO_WIDTH
    self.height ||= DefaultSetting::VIDEO_HEIGHT
  end

  def set_video_stream_defaults
    self.embedded_width ||=  DefaultSetting::EMBEDDED_WIDTH
    self.embedded_height ||= DefaultSetting::EMBEDDED_HEIGHT
    self.video_player = video_player.presence || DefaultSetting::VIDEO_PLAYER
    self.authoring_software = authoring_software.presence ||
                              DefaultSetting::AUTHORING_SOFTWARE
  end

  def fill_in_defaults_for_missing_params
    set_keks_defaults if sort == 'KeksQuestion'
    set_video_defaults if video_content?
    set_video_stream_defaults if video_stream_link.present?
  end

  def touch_teachable
    return if teachable.nil?
    teachable.course.touch
    optional_touches
  end

  def optional_touches
    teachable.lecture.touch if teachable.lecture.present?
    teachable.lesson.touch if teachable.lesson.present?
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
end
