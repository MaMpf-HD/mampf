class MigrateTagTitlesToNotion < ActiveRecord::Migration[6.0]
  def change
    add_column :notions, :tag_id, :integer
    add_index :notions, :tag_id
    Tag.all.each do |t|
      Notion.create(title: t.title, locale: I18n.default_locale, tag_id: t.id)
    end
  end
end
