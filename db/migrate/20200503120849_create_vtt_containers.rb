class CreateVttContainers < ActiveRecord::Migration[6.0]
  def change
    create_table :vtt_containers do |t|
      t.text :table_of_contents_data
      t.text :references_data

      t.timestamps
    end
  end
end
