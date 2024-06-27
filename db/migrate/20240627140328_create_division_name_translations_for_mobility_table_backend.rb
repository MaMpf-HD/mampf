class CreateDivisionNameTranslationsForMobilityTableBackend < ActiveRecord::Migration[7.1]
  def change
    create_table :division_translations do |t|

      # Translated attribute(s)
      t.text :name

      t.string  :locale, null: false
      t.references :division, null: false, foreign_key: true, index: false

      t.timestamps null: false
    end

    add_index :division_translations, :locale, name: :index_division_translations_on_locale
    add_index :division_translations, [:division_id, :locale], name: :index_division_translations_on_division_id_and_locale, unique: true

  end
end
