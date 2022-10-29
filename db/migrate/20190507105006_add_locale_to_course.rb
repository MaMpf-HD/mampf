class AddLocaleToCourse < ActiveRecord::Migration[6.0]
  def change
    add_column :courses, :locale, :text
  end
end
