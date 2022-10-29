class RemoveAnswerSchemeFromProbe < ActiveRecord::Migration[6.0]
  def change
    remove_column :probes, :answer_scheme, :text
  end
end
