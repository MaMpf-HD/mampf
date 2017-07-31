# SectionTagJoin class
# Join table for section<->tag many-to-many-relation
class SectionTagJoin < ApplicationRecord
  belongs_to :section
  belongs_to :tag
end
