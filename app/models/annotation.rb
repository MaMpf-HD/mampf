class Annotation < ApplicationRecord
  belongs_to :medium
  belongs_to :user
  enum category: { other: 0, note: 1, comment: 2, mistake: 3, help: 4 }
end
