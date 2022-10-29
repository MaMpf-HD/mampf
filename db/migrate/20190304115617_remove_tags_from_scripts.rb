class RemoveTagsFromScripts < ActiveRecord::Migration[5.2]
  def change
    Medium.where(sort: 'Script').each do |m|
      m.update(tags: [])
    end
  end
end
