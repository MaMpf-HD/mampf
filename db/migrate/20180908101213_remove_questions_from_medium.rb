# rubocop:disable Rails/
class RemoveQuestionsFromMedium < ActiveRecord::Migration[5.2]
  def change
    remove_column :media, :question_id, :integer
    remove_column :media, :question_list, :text
  end
end
# rubocop:enable Rails/