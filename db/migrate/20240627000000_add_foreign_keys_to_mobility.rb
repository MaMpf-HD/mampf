class AddForeignKeysToMobility < ActiveRecord::Migration[7.1]
  def change
    add_foreign_key :subject_translations, :subjects
    add_foreign_key :program_translations, :programs
    add_foreign_key :division_translations, :divisions
  end
end
