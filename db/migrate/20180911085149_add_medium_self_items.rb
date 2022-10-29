class AddMediumSelfItems < ActiveRecord::Migration[5.2]
  def change
    Medium.all.each do |m|
      unless Item.where(sort: 'self', medium: m).present?
        Item.create(sort: 'self', medium: m)
      end
    end
  end
end
