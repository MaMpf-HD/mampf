# LearningAsset class
class LearningAsset < ApplicationRecord
  belongs_to :teachable, polymorphic: true
  has_many :asset_media
  has_many :media, through: :asset_media
  has_many :asset_tags
  has_many :tags, through: :asset_tags
  has_many :connections
  has_many :linked_assets, through: :connections
  validates :title, presence: true, uniqueness: true
  validates :question_list, presence: true,
                            format: { with: /\A(\d{1,}&)+\d{1,}\z/ },
                            if: :keks_quiz?

  def neighbours
    LearningAsset.where(id: Connection.select(:linked_asset_id)
                                      .where(learning_asset_id: id))
                 .or(LearningAsset.where(id: Connection
                                             .select(:learning_asset_id)
                                             .where(linked_asset_id: id)))
  end

  def keks_quiz?
    type == 'KeksQuizAsset'
  end
end
