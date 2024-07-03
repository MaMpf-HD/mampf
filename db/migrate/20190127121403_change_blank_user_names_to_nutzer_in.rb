# rubocop:disable Rails/
class ChangeBlankUserNamesToNutzerIn < ActiveRecord::Migration[5.2]
  def change
    User.where(name: "").update_all(name: "NutzerIn")
  end
end
# rubocop:enable Rails/
