class RemoveSubtextFromAnnotation < ActiveRecord::Migration[7.0]
  def change
  	remove_column :annotations, :subtext, :text
  end
end
