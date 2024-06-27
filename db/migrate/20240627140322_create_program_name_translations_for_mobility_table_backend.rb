class CreateProgramNameTranslationsForMobilityTableBackend < ActiveRecord::Migration[7.1]
  def change
    create_table :program_translations do |t|

      # Translated attribute(s)
      t.text :name

      t.string  :locale, null: false
      t.references :program, null: false, foreign_key: true, index: false

      t.timestamps null: false
    end

    add_index :program_translations, :locale, name: :index_program_translations_on_locale
    add_index :program_translations, [:program_id, :locale], name: :index_program_translations_on_program_id_and_locale, unique: true

  end
end
