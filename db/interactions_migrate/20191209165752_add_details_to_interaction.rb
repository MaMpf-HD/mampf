# rubocop:disable Rails/
class AddDetailsToInteraction < ActiveRecord::Migration[6.0]
  def change
    add_column :interactions, :controller_name, :text
    add_column :interactions, :action_name, :text
    add_column :interactions, :referrer_url, :text
  end
end
# rubocop:enable Rails/
