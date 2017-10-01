# Connection class
# JoinTable for medium<->medium many-to-many-relation
class Link < ApplicationRecord
  belongs_to :medium
  belongs_to :linked_medium, class_name: "Medium"
  after_create :destroy_link, if: :self_inverse?

  private

  def self_inverse?
    medium_id == linked_medium_id
  end

  def destroy_link
    self.destroy
  end
end
