# SectionTagJoin class
# Join table for section<->tag many-to-many-relation
class SectionTagJoin < ApplicationRecord
#	default_scope { order :tag_position }
  belongs_to :section
  belongs_to :tag
#  acts_as_list scope: :section, top_of_list: 0, column: :tag_position
end
