class ChangeNilUserNamesToBlank < ActiveRecord::Migration[5.2]
  def change
    User.where(name: nil).update_all(name: "") # rubocop:todo Rails/SkipsModelValidations
  end
end
