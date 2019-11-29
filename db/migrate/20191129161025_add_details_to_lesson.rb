class AddDetailsToLesson < ActiveRecord::Migration[6.0]
  def change
    add_column :lessons, :details, :text
  end
end
