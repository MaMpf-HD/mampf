class CreateSubjectNameTranslationsForMobilityTableBackend < ActiveRecord::Migration[7.1]
  def change
    create_table :subject_translations do |t|

      # Translated attribute(s)
      t.text :name

      t.string  :locale, null: false
      t.references :subject, null: false, foreign_key: true, index: false

      t.timestamps null: false
    end

    add_index :subject_translations, :locale, name: :index_subject_translations_on_locale
    add_index :subject_translations, [:subject_id, :locale], name: :index_subject_translations_on_subject_id_and_locale, unique: true

  end
end
