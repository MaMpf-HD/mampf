class AddReleasedToMedium < ActiveRecord::Migration[5.2]
  def change
    add_column :media, :released, :text
    Medium.all.update_all(released: "all") # rubocop:todo Rails/SkipsModelValidations
  end
end
