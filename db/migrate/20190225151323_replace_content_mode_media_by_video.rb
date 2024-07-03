# rubocop:disable Rails/
class ReplaceContentModeMediaByVideo < ActiveRecord::Migration[5.2]
  def change
    Lecture.all.update_all(content_mode: "video")
  end
end
# rubocop:enable Rails/
