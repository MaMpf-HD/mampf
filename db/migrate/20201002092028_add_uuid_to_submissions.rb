class AddUuidToSubmissions < ActiveRecord::Migration[6.0]
  def change
    add_column :submissions, :uuid, :uuid, default: "gen_random_uuid()",
               null: false
  end
end
