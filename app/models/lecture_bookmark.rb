# LectureBookmark class
# JoinTable for lecture <-> user many-to-many-relation
# describes which users have bookmarked a lecture (formerly: subscribed it).
# For now, a bookmark also unlocks a passphrase-protected lecture, see
# Lecture#unlocked_for?.
class LectureBookmark < ApplicationRecord
  belongs_to :lecture
  belongs_to :user
end
