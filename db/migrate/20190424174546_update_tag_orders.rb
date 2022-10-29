class UpdateTagOrders < ActiveRecord::Migration[5.2]
  def change
    Section.all.each do |s|
      s.update(tags_order: s.tag_ids)
    end
  end
end
