# Reader model
# Reader keeps track of when a user hast last seen a certain thread,
# making it possible to display whether there are new comments
class Reader < ApplicationRecord
  belongs_to :user
  belongs_to :thread, class_name: 'Commontator::Thread'
end
