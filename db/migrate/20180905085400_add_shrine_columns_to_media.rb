# rubocop:disable Rails/
class AddShrineColumnsToMedia < ActiveRecord::Migration[5.2]
  def change
    add_column :media, :video_data, :text
    add_column :media, :screenshot_data, :text
    add_column :media, :manuscript_data, :text
  end
end
# rubocop:enable Rails/
