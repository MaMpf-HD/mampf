# One correction of a user's locked personal data by the support, kept
# because exam lists and grade exports go by these fields.
class PersonalDataChange < ApplicationRecord
  belongs_to :user
  belongs_to :editor, class_name: "User", optional: true

  validates :field, inclusion: { in: User::LOCKED_PERSONAL_DATA_FIELDS.map(&:to_s) }

  # Saves the corrected fields and records each one that changed, or
  # neither when the user does not validate.
  def self.correct!(user, attributes, editor:)
    user.assign_attributes(attributes.to_h.slice(*User::LOCKED_PERSONAL_DATA_FIELDS.map(&:to_s)))
    changes = user.changes.slice(*User::LOCKED_PERSONAL_DATA_FIELDS.map(&:to_s))
    transaction do
      user.save!
      changes.each do |field, (old_value, new_value)|
        create!(user: user, editor: editor, field: field,
                old_value: old_value, new_value: new_value)
      end
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
