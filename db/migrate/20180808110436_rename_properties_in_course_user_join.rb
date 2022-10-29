class RenamePropertiesInCourseUserJoin < ActiveRecord::Migration[5.2]
  def change
    rename_column :course_user_joins, :sesam, :sesam?
    rename_column :course_user_joins, :keks, :keks?
    rename_column :course_user_joins, :erdbeere, :erdbeere?
    rename_column :course_user_joins, :kiwi, :kiwi?
    rename_column :course_user_joins, :reste, :reste?
    rename_column :course_user_joins, :news, :news?                
  end
end
