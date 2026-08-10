# See altcha-rails
# https://github.com/zonque/altcha-rails
# Migration taken from update step 6 from "Upgrade guide from 0.0.x"
# https://github.com/zonque/altcha-rails#upgrade-guide-from-00x
class DropAltchaSolutions < ActiveRecord::Migration[8.0]
  def up
    drop_table :altcha_solutions
  end

  def down
    create_table :altcha_solutions do |t|
      t.string  :algorithm
      t.string  :challenge
      t.string  :salt
      t.string  :signature
      t.integer :number

      t.timestamps
    end

    add_index :altcha_solutions,
              [:algorithm, :challenge, :salt, :signature, :number],
              unique: true,
              name: "index_altcha_solutions"
  end
end
