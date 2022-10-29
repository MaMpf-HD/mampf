class CreateTutorTutorialJoins < ActiveRecord::Migration[6.0]
  def up
    create_table :tutor_tutorial_joins do |t|
      t.references :tutorial, null: false, foreign_key: true
      t.references :tutor, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end
  end

  def down
  	drop_table :tutor_tutorial_joins
  end
end
