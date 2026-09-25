# Every existing lecture subscription carries over as a bookmark.
class RenameLectureUserJoinsToLectureBookmarks < ActiveRecord::Migration[8.0]
  def change
    rename_table :lecture_user_joins, :lecture_bookmarks
  end
end
