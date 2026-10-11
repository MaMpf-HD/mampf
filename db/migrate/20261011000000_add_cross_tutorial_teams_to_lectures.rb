# Lets a lecture keep its submission teams within one tutorial. On by
# default, which is how teams have behaved so far.
class AddCrossTutorialTeamsToLectures < ActiveRecord::Migration[8.0]
  def change
    add_column :lectures, :cross_tutorial_teams, :boolean, default: true, null: false
  end
end
