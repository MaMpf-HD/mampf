# The old feedback form's table was dropped in `DropFeedbacks`. This one holds
# the answers of the temporary "What can we improve?" survey instead.
class RecreateFeedbacks < ActiveRecord::Migration[8.0]
  def change
    create_table :feedbacks do |t|
      t.text :body, null: false
      t.timestamps
    end
  end
end
