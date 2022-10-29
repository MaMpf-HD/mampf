class RenameMediaSortResteToNuesse < ActiveRecord::Migration[5.2]
  def change
    Medium.where(sort: 'Reste').each do |m|
      m.update(sort: 'Nuesse')
    end
  end
end
