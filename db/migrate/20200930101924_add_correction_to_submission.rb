class AddCorrectionToSubmission < ActiveRecord::Migration[6.0]
  def change
    add_column :submissions, :correction_data, :text
  end
end
