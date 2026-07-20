class RemovePlanningOnlyAndLectureCapacity < ActiveRecord::Migration[8.0]
  def change
    remove_column :registration_campaigns, :planning_only, :boolean
    remove_column :lectures, :capacity, :integer
  end
end
