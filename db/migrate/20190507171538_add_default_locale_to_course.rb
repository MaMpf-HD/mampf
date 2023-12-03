class AddDefaultLocaleToCourse < ActiveRecord::Migration[6.0]
  def change
    Course.update_all(locale: I18n.default_locale.to_s) # rubocop:todo Rails/SkipsModelValidations
    Lecture.update_all(locale: I18n.default_locale.to_s) # rubocop:todo Rails/SkipsModelValidations
    User.update_all(locale: I18n.default_locale.to_s) # rubocop:todo Rails/SkipsModelValidations
  end
end
