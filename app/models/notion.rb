class Notion < ApplicationRecord
  belongs_to :tag, optional: true, touch: true
  belongs_to :aliased_tag, class_name: "Tag", optional: true, touch: true

  validates :title, uniqueness: { scope: :locale }
  validates :title, presence: true
  validate :presence_of_tag, if: :persisted?

  after_save :touch_tag_relations
  before_destroy :touch_tag_relations

  def presence_of_tag
    return if tag || aliased_tag

    errors.add(:tag, :no_tag)
  end

  def touch_tag_relations
    tag&.touch_lectures
    tag&.touch_sections
    tag&.touch_chapters
    aliased_tag&.touch_lectures
    aliased_tag&.touch_sections
    aliased_tag&.touch_chapters
    clear_tag_cache
  end

  private

    def clear_tag_cache
      I18n.available_locales.each do |l|
        Rails.cache.delete("tag_select_by_title_#{l}")
      end
    end
end
