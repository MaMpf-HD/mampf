# AdditionalContent class
# JoinTable for lecture <-> tag many-to-many-relation
class AdditionalContent < ApplicationRecord
  belongs_to :lecture
  belongs_to :tag
end
