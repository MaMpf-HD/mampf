class AddShortTitleToCourse < ActiveRecord::Migration[5.1]
  def change
    add_column :courses, :short_title, :string
  end
end
