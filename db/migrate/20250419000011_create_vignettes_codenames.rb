class CreateVignettesCodenames < ActiveRecord::Migration[7.1]
  def change
    create_table :vignettes_codenames do |t|
      t.string :pseudonym
      t.belongs_to :user, foreign_key: true
      t.belongs_to :lecture, foreign_key: true

      t.timestamps
    end
  end
end
