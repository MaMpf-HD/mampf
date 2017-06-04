class CreateExternalReferences < ActiveRecord::Migration[5.1]
  def change
    create_table :external_references do |t|
      t.string :description

      t.timestamps
    end
  end
end
