class Notion < ApplicationRecord
  belongs_to :tag, optional: true
  belongs_to :aliased_tag, class_name: "Tag", optional: true

  validates :title, uniqueness: { scope: :locale }
  validates :title, presence: true
  validate :presence_of_tag, if: :persisted?

  before_destroy :clear_tag_cache
  after_save :clear_tag_cache

  def presence_of_tag
    return if tag || aliased_tag

    errors.add(:tag, :no_tag)
  end

  private

    def clear_tag_cache
      I18n.available_locales.each do |l|
        Rails.cache.delete("tag_select_by_title_#{l}")
      end
    end
end
