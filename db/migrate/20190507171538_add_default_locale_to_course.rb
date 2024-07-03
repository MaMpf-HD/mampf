# rubocop:disable Rails/
class AddDefaultLocaleToCourse < ActiveRecord::Migration[6.0]
  def change
    Course.update_all(locale: I18n.default_locale.to_s)
    Lecture.update_all(locale: I18n.default_locale.to_s)
    User.update_all(locale: I18n.default_locale.to_s)
  end
end
# rubocop:enable Rails/
