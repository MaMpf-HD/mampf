class RemoveUniquenessIndexFromRegistrationPolicies < ActiveRecord::Migration[8.0]
  def change
    remove_index :registration_policies, name: "index_registration_policies_uniqueness"
    add_index :registration_policies, [:registration_campaign_id, :position],
              name: "index_registration_policies_position"
  end
end
