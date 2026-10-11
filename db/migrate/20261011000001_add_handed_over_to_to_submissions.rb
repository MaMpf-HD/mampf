class AddHandedOverToToSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_reference :submissions, :handed_over_to,
                  foreign_key: { to_table: :tutorials, on_delete: :nullify }
  end
end
