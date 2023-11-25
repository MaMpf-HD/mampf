class RemoveQuestionsFromMedium < ActiveRecord::Migration[5.2]
  def change
    remove_column :media, :question_id, :integer # rubocop:todo Rails/BulkChangeTable
    remove_column :media, :question_list, :text
  end
end
