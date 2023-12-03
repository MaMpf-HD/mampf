# rubocop:disable Rails/
class GenerateNotionsFromTagTitles < ActiveRecord::Migration[6.0]
  def change
    Tag.all.each do |t|
      Notion.create(title: t.title_backup,
                    locale: I18n.default_locale,
                    tag_id: t.id)
    end
  end
end
# rubocop:enable Rails/
