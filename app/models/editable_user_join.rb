# EditableUserJoin class
# Join Table for polymorphic many-to-many relation User <-> Editable
# here Editable stand for Course, Lecture, Medium
# the relation describes which users can edit these
class EditableUserJoin < ApplicationRecord
  belongs_to :editable, polymorphic: true
  belongs_to :user
end
