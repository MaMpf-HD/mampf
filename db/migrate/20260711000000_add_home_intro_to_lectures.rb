class AddHomeIntroToLectures < ActiveRecord::Migration[8.0]
  def change
    add_column :lectures, :home_intro, :text
    add_column :lectures, :home_attachment_data, :text
  end
end
