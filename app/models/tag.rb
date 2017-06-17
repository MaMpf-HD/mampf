class Tag < ApplicationRecord
  alias_attribute :disabled_lectures, :lectures
  has_many :course_contents
  has_many :courses, through: :course_contents
  has_many :disabled_contents
  has_many :lectures, through: :disabled_contents
  has_many :lesson_contents
  has_many :lessons, through: :lesson_contents
  has_many :asset_tags
  has_many :learning_assets, through: :asset_tags
  has_many :relations, dependent: :destroy
  has_many :related_tags, through: :relations, dependent: :destroy

  def neighbours
    Tag.where(id: Relation.select(:related_tag_id).where(tag_id: id))
       .or(Tag.where(id: Relation.select(:tag_id).where(related_tag_id: id)))
  end
end
