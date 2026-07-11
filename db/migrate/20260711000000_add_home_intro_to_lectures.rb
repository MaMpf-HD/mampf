class AddHomeIntroToLectures < ActiveRecord::Migration[8.0]
  def change
    # Teacher-authored welcome/organizational text shown at the top of the
    # lecture home page, plus an optional PDF program (Shrine attachment).
    add_column :lectures, :home_intro, :text
    add_column :lectures, :home_attachment_data, :text
  end
end
