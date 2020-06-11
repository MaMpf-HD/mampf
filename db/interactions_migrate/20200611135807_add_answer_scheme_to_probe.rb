class AddAnswerSchemeToProbe < ActiveRecord::Migration[6.0]
  def change
    add_column :probes, :answer_scheme, :text
  end
end
