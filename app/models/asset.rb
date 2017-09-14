# Asset class
class Asset < ApplicationRecord
  belongs_to :teachable, polymorphic: true
  has_many :asset_medium_joins
  has_many :media, through: :asset_medium_joins
  has_many :connections
  has_many :linked_assets, through: :connections
  validates :title, presence: true, uniqueness: true
  validates :sort, presence: true,
                   inclusion: { in: %w[Kaviar Erdbeere Sesam Reste KeksQuiz] }
  validates :question_list, presence: true,
                            format: { with: /\A(\d{1,}&)+\d{1,}\z/ },
                            if: :keks_quiz?

  def neighbours
    Asset.where(id: Connection.select(:linked_asset_id)
                                      .where(asset_id: id))
         .or(Asset.where(id: Connection.select(:asset_id)
                                       .where(linked_asset_id: id)))
  end

  def keks_quiz?
    sort == 'KeksQuiz'
  end

  def tags
    Tag.where(id: media.all.map(&:tags).flatten.map(&:id))
  end
end
