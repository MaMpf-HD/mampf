class AddCrossTutorialTeamsToLectures < ActiveRecord::Migration[8.0]
  def change
    add_column :lectures, :cross_tutorial_teams, :boolean, default: false, null: false
  end
end
