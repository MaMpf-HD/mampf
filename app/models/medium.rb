# Medium class
class Medium < ApplicationRecord
  has_many :asset_media
  has_many :learning_assets, through: :asset_media
  validates :author, presence: true
  validates :title, presence: true
  validate :nonempty_content?
  validates :video_size, presence: true,
                         format:
                           { with: /\A([\d,.]+)?\s?(?:([kmgtpezy])i)?b\z/i },
                         if: :video_file_content?

  def nonempty_content?
    return true if video_stream_link.present? ||
                   video_file_link.present? ||
                   manuscript_link.present? ||
                   external_reference_link.present?
    errors.add(:base, 'empty content')
    false
  end

  def video_file_content?
    video_file_link.present?
  end
end
