# `email_for_news` covered emails about site-wide announcements, but those
# don't send emails anymore, so we can remove this column.
class RemoveEmailForNewsFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column(:users, :email_for_news, :boolean)
  end
end
