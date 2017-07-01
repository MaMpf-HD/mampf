class ChangeSizesFormatInMedia < ActiveRecord::Migration[5.1]
  def up
   change_column :media, :video_size, :string
   change_column :media, :manuscript_size, :string
  end

  def down
   change_column :media, :video_size, :bigint
   change_column :media, :manuscript_size, :integer
  end
end
