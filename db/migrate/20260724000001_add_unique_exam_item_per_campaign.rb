class AddUniqueExamItemPerCampaign < ActiveRecord::Migration[8.0]
  def change
    add_index :registration_items, :registration_campaign_id,
              unique: true,
              where: "registerable_type = 'Exam'",
              name: "index_registration_items_on_unique_exam_per_campaign"
  end
end
