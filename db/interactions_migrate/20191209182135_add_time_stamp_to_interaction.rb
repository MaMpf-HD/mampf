class AddTimeStampToInteraction < ActiveRecord::Migration[6.0]
  def change
    add_column :interactions, :created_at, :datetime
  end
end
