# Medium class
class Medium < ApplicationRecord
  has_many :asset_medium_joins
  has_many :assets, through: :asset_medium_joins
  has_many :medium_tag_joins
  has_many :tags, through: :medium_tag_joins
  belongs_to :teachable, polymorphic: true
  validates :sort, presence: true,
                   inclusion: { in: %w[Kaviar Erdbeere Sesam Reste
                                       KeksQuestion] }
  validates :question_id, presence: true, uniqueness: true, if: :keks_question?
  validates :author, presence: true
  validates :title, presence: true, uniqueness: true
  validates :description, presence: true
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

  def video_content?
    video_stream_link.present? || video_file_link.present?
  end

  def video_stream_content?
    video_stream_link.present?
  end

  def video_file_content?
    video_file_link.present?
  end

  def manuscript_content?
    manuscript_link.present?
  end

  def keks_question?
    sort == 'KeksQuestion'
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
    return heading unless heading.nil?
    return '' unless sort == 'Kaviar' && teachable_type='Lesson'
    return teachable.section_titles
  end

  def tag_titles
    tags.map(&:title).join(', ')
  end

  def teachable_type
    teachable.class.name
  end

  scope :KeksQuestion, -> { where(sort: 'KeksQuestion') }
  scope :Kaviar, ->{ where(sort: 'Kaviar') }

  private

  def nonempty_content?
    return true if video_stream_link.present? ||
                   video_file_link.present? ||
                   manuscript_link.present? ||
                   external_reference_link.present?
    errors.add(:base, 'empty content')
    false
  end
end
