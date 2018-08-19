# EditableUserJoin class
# Join Table for polymorphic many-to-many relation User <-> Course, Lecture,...
class EditableUserJoin < ApplicationRecord
  belongs_to :editable, polymorphic: true
  belongs_to :user
end
