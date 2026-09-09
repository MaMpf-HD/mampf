class AddUniqueStudentPerformancePolicyPerCampaign < ActiveRecord::Migration[8.0]
  def change
    # kind = 2 is Registration::Policy.kinds[:student_performance]
    add_index :registration_policies, :registration_campaign_id,
              unique: true,
              where: "kind = 2",
              name: "index_one_student_performance_policy_per_campaign"
  end
end
