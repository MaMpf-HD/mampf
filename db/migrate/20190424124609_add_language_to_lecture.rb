class AddLanguageToLecture < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :language, :text
  end
end
