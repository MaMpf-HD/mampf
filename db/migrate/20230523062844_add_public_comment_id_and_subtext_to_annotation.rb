class AddPublicCommentIdAndSubtextToAnnotation < ActiveRecord::Migration[7.0]
  def change
    add_column :annotations, :public_comment_id, :integer
    add_column :annotations, :subtext, :text
  end
end
