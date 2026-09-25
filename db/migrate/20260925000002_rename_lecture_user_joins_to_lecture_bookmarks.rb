# The former lecture subscriptions are now read as bookmarks: every existing
# subscription carries over as a bookmark, so nobody loses their lecture
# history. For now, a bookmark also unlocks a passphrase-protected lecture.
class RenameLectureUserJoinsToLectureBookmarks < ActiveRecord::Migration[8.0]
  def change
    rename_table :lecture_user_joins, :lecture_bookmarks
  end
end
