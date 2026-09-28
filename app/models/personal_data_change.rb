# Records one correction of a user's LOCKED_PERSONAL_DATA_FIELDS: who changed
# which field from what to what. Exam lists show students by these fields.
class PersonalDataChange < ApplicationRecord
  belongs_to :user
  belongs_to :editor, class_name: "User", optional: true

  validates :field, inclusion: { in: User::LOCKED_PERSONAL_DATA_FIELDS.map(&:to_s) }
  validates :editor, presence: true, on: :create

  # Saves the corrected fields and records each one that changed; returns the
  # changed fields, or nil and saves neither when the user does not validate.
  def self.correct(user, attributes, editor:)
    fields = User::LOCKED_PERSONAL_DATA_FIELDS.map(&:to_s)
    user.assign_attributes(attributes.to_h.slice(*fields))
    changes = user.changes.slice(*fields)
    transaction do
      user.save!
      changes.each do |field, (old_value, new_value)|
        create!(user: user, editor: editor, field: field,
                old_value: old_value, new_value: new_value)
      end
    end
    changes.keys
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    nil
  end

  # Keeps a recorded correction as it was. Deleting the user still removes it:
  # dependent: :delete_all and the cascading foreign key skip this check.
  def readonly?
    persisted?
  end
end
