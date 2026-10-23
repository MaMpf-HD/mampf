# The support button mails its messages and stores none; this table held the
# messages of the feedback form it replaced, which nobody reads any more.
class DropFeedbacks < ActiveRecord::Migration[8.0]
  def change
    drop_table :feedbacks do |t|
      t.text :title
      t.text :feedback
      t.boolean :can_contact, default: false, null: false
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
