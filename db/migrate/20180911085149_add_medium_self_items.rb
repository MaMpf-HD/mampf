# rubocop:disable Rails/
class AddMediumSelfItems < ActiveRecord::Migration[5.2]
  def change
    Medium.all.each do |m|
      Item.create(sort: "self", medium: m) unless Item.where(sort: "self", medium: m).present?
    end
  end
end
# rubocop:enable Rails/
