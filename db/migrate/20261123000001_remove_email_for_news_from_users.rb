# Without MaMpf News, there is nothing left to send news emails about.
class RemoveEmailForNewsFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column(:users, :email_for_news, :boolean)
  end
end
