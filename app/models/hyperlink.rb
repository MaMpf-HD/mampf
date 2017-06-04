class Hyperlink < ApplicationRecord
  belongs_to :linkable, polymorphic: true
end
