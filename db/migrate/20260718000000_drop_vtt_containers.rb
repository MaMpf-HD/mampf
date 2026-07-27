class DropVttContainers < ActiveRecord::Migration[8.0]
  def change
    drop_table :vtt_containers do |t|
      t.text :table_of_contents_data
      t.text :references_data
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
  end
end
