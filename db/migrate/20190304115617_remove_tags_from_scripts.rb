class RemoveTagsFromScripts < ActiveRecord::Migration[5.2]
  def change
    Medium.where(sort: 'Script').update_all(tags: [])
  end
end
