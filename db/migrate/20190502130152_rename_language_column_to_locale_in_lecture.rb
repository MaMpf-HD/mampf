class RenameLanguageColumnToLocaleInLecture < ActiveRecord::Migration[6.0]
  def change
    rename_column :lectures, :language, :locale
  end
end
