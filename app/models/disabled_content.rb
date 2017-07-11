# DisabledContent class
# JoinTable for lecture <-> tag many-to-many-relation
class DisabledContent < ApplicationRecord
  belongs_to :lecture
  belongs_to :tag
end
