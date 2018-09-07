class MergeHeadingAndDescriptionInMedium < ActiveRecord::Migration[5.2]
  def change
    Medium.select { |m| m.heading.present? }.each do |m|
      m.update(description: m.heading)
    end
  end
end
