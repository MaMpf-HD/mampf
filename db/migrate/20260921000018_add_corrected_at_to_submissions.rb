class AddCorrectedAtToSubmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :submissions, :corrected_at, :datetime, null: true
  end
end
