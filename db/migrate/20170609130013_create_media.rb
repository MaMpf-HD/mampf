class CreateMedia < ActiveRecord::Migration[5.1]
  def change
    create_table :media do |t|
      t.string :title
      t.string :author
      t.text :link

      t.timestamps
    end
  end
end
