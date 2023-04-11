class Annotation < ApplicationRecord
  belongs_to :medium
  belongs_to :user
  
  # the timestamp for the annotation position is serialized as text in the db
  serialize :timestamp, TimeStamp
  
  enum category: { note: 0, content: 1, mistake: 2, presentation: 3 }
end
