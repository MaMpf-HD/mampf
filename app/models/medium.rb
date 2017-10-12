# Medium class
class Medium < ApplicationRecord
  has_many :medium_tag_joins
  has_many :tags, through: :medium_tag_joins
  has_many :links, dependent: :destroy
  has_many :linked_media, through: :links, dependent: :destroy
  belongs_to :teachable, polymorphic: true
  after_create :create_keks_link, if: :keks_link_missing?
  validates :sort, presence: true,
                   inclusion: { in: %w[Kaviar Erdbeere Sesam Reste
                                       KeksQuestion KeksQuiz] }
  validates :question_id, presence: true, uniqueness: true, if: :keks_question?
  validates :author, presence: true
  validates :title, presence: true, uniqueness: true
  validate :nonempty_content?
  validates :width, presence: true,
                    numericality: { only_integer: true,
                                    greater_than_or_equal_to: 100,
                                    less_than_or_equal_to: 8192 },
                    if: :video_content?
  validates :height, presence: true,
                     numericality: { only_integer: true,
                                     greater_than_or_equal_to: 100,
                                     less_than_or_equal_to: 4320 },
                     if: :video_content?
  validates :embedded_width, presence: true,
                             numericality: { only_integer: true,
                                             greater_than_or_equal_to: 100,
                                             less_than_or_equal_to: 8192 },
                             if: :video_content?
  validates :embedded_height, presence: true,
                              numericality: { only_integer: true,
                                              greater_than_or_equal_to: 100,
                                              less_than_or_equal_to: 4320 },
                              if: :video_content?

  validates :length, presence: true,
                     format: { with: /\A[0-9]h[0-5][0-9]m[0-5][0-9]s\z/ },
                     if: :video_content?

  # video_size, manuscript_size are in a format compatible with 'filesize' gem
  validates :video_size, presence: true,
                         format:
                           { with: /\A([\d,.]+)?\s?(?:([kmgtpezy])i)?b\z/i },
                         if: :video_file_content?
  validates :pages, presence: true,
                    numericality: { only_integer: true,
                                    greater_than_or_equal_to: 1,
                                    less_than_or_equal_to: 2000 },
                    if: :manuscript_content?
  validates :manuscript_size, presence: true,
                              format:
                                { with: /\A([\d,.]+)?\s?(?:([kmgtpezy])i)?b\z/i },
                              if: :manuscript_content?

  def video_aspect_ratio
    return unless height != 0 && width != 0
    width.to_f / height
  end

  def video_scaled_height(new_width)
    return unless height != 0 && width != 0
    (new_width.to_f / video_aspect_ratio).to_i
  end

  def caption
    return heading unless heading.nil?
    return unless sort == 'Kaviar' && teachable_sort == 'Lesson'
    teachable.section_titles
  end

  def tag_titles
    tags.map(&:title).join(', ')
  end

  def card_header
    teachable.description[:general]
  end

  def card_header_teachable
    return teachable unless teachable_sort == 'Lesson'
    teachable.lecture
  end


  def card_subheader
    return description if description.present?
    return teachable.description[:specific] unless teachable.description[:specific].nil?
    { 'KeksQuestion' => 'KeKs Frage Nr. ' + question_id.to_s,
      'KeksQuiz' => 'KeksQuiz', 'Sesam' => 'SeSAM Video' }[sort]
  end

  def card_subheader_teachable
    return if description.present? ||  teachable.description[:specific].nil?
    teachable
  end


  def sort_de
    { 'Kaviar' => 'KaViaR', 'Sesam' => 'SeSAM',
      'KeksQuestion' => 'Keks-Frage', 'KeksQuiz' => 'Keks-Quiz',
      'Reste' => 'RestE', 'Erdbeere' => 'ErDBeere' }[sort]
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

  def keks_link_missing?
    return false unless sort == 'KeksQuestion' && external_reference_link.nil?
    true
  end

  def create_keks_link
    self.update(external_reference_link:
                  'https://keks.mathi.uni-heidelberg.de/hitme#hide-options' +
                  '#hide-categories#question=' + question_id.to_s)
  end

  def related_to_lecture?(lecture)
    case teachable_sort
    when 'Course'
      return true if teachable == lecture.course
    when 'Lecture'
      return true if teachable == lecture
    when 'Lesson'
      return true if teachable.lecture == lecture
    end
    false
  end

  def related_to_lectures?(lectures)
    lectures.map{ |l| related_to_lecture?(l) }.include?(true)
  end

  scope :KeksQuestion, -> { where(sort: 'KeksQuestion') }
  scope :Kaviar, -> { where(sort: 'Kaviar') }

  private

  def video_content?
    video_stream_link.present? || video_file_link.present?
  end

  def video_file_content?
    video_file_link.present?
  end

  def manuscript_content?
    manuscript_link.present?
  end

  def nonempty_content?
    return true if video_stream_link.present? ||
                   video_file_link.present? ||
                   manuscript_link.present? ||
                   external_reference_link.present?
    errors.add(:base, 'empty content')
    false
  end

  def keks_question?
    sort == 'KeksQuestion'
  end
end
