class AddStartSectionToLecture < ActiveRecord::Migration[5.2]
  def change
    add_column :lectures, :start_section, :integer
  end
end
