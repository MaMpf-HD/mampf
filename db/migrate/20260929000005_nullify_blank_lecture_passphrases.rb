# Lecture normalizes a blank passphrase to nil, and so do queries on it:
# `where(passphrase: "")` asks for NULL. Rows saved before that still hold
# "", which such queries would take for a passphrase.
class NullifyBlankLecturePassphrases < ActiveRecord::Migration[8.0]
  def up
    execute("UPDATE lectures SET passphrase = NULL WHERE passphrase = ''")
  end

  # "" and NULL both mean no passphrase; nothing to restore.
  def down
  end
end
