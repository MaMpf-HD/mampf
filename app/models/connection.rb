# Connection class
# JoinTable for lecture<->lecture many-to-many-relation
class Connection < ApplicationRecord
  belongs_to :lecture
  belongs_to :preceding_lecture, class_name: 'Lecture'
  after_save :destroy, if: :self_inverse?

  private

  def self_inverse?
    lecture_id == preceding_lecture_id
  end
end
