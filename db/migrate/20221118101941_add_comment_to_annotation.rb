class AddCommentToAnnotation < ActiveRecord::Migration[6.1]
  def change
    add_column :annotations, :comment, :text
  end
end
