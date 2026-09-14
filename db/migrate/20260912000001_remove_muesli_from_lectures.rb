class RemoveMuesliFromLectures < ActiveRecord::Migration[8.0]
  def change
    remove_column :lectures, :muesli, :boolean
  end
end
