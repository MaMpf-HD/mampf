# rubocop:disable Rails/
class RemoveColumsFromMedium < ActiveRecord::Migration[6.0]
  def change
    remove_column :media, :video_file_link, :text

    remove_column :media, :video_stream_link, :text

    remove_column :media, :video_thumbnail_link, :text

    remove_column :media, :manuscript_link, :text

    remove_column :media, :extras_link, :text

    remove_column :media, :extras_description, :text
  end
end
# rubocop:enable Rails/
