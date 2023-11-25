class CreateAnswers < ActiveRecord::Migration[5.2]
  def change
    create_table :answers do |t|
      t.text :text
      t.boolean :value # rubocop:todo Rails/ThreeStateBooleanColumn
      t.text :explanation

      t.timestamps
    end
  end
end
