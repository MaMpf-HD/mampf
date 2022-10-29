class AddContentModeToLecture < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :content_mode, :text
    Lecture.all.update_all(content_mode: 'media')
  end
end
