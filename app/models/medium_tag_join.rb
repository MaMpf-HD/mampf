# MediumTagJoin class
# Join table for medium<->tag many-to-many-relation
class MediumTagJoin < ApplicationRecord
  belongs_to :medium
  belongs_to :tag
end
