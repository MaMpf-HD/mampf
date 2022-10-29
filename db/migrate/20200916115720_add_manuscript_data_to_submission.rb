class AddManuscriptDataToSubmission < ActiveRecord::Migration[6.0]
  def change
    add_column :submissions, :manuscript_data, :text
  end
end
