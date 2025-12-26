# NOTE: This migration does not migrate existing data in the registration tables.
# It only changes the primary key and foreign key columns to use UUIDs.
# Existing data migration would require a more complex approach and is not covered here
# as the corresponding tables are empty at this point in the application lifecycle.
class ConvertRegistrationTablesToUuid < ActiveRecord::Migration[8.0]
  def up
    # Remove existing foreign keys to avoid dependency issues during column removal
    remove_foreign_key :registration_items, :registration_campaigns
    remove_foreign_key :registration_policies, :registration_campaigns
    remove_foreign_key :registration_user_registrations, :registration_campaigns
    remove_foreign_key :registration_user_registrations, :registration_items

    # Registration Campaigns
    remove_column :registration_campaigns, :id
    add_column :registration_campaigns, :id, :uuid, default: "gen_random_uuid()",
                                                    primary_key: true

    # Registration Items
    remove_column :registration_items, :id
    remove_column :registration_items, :registration_campaign_id

    add_column :registration_items, :id, :uuid, default: "gen_random_uuid()",
                                                primary_key: true
    add_column :registration_items, :registration_campaign_id, :uuid, null: false

    add_index :registration_items, :registration_campaign_id
    add_index :registration_items,
              [:registration_campaign_id, :registerable_type, :registerable_id],
              unique: true, name: "index_registration_items_uniqueness"

    # Registration Policies
    remove_column :registration_policies, :id
    remove_column :registration_policies, :registration_campaign_id

    add_column :registration_policies, :id, :uuid, default: "gen_random_uuid()", primary_key: true
    add_column :registration_policies, :registration_campaign_id, :uuid, null: false

    add_index :registration_policies, :registration_campaign_id
    add_index :registration_policies, [:registration_campaign_id, :position],
              unique: true,
              name: "index_registration_policies_uniqueness"

    # Registration User Registrations
    remove_column :registration_user_registrations, :id
    remove_column :registration_user_registrations, :registration_campaign_id
    remove_column :registration_user_registrations, :registration_item_id

    add_column :registration_user_registrations, :id, :uuid, default: "gen_random_uuid()",
                                                             primary_key: true
    add_column :registration_user_registrations, :registration_campaign_id, :uuid, null: false
    add_column :registration_user_registrations, :registration_item_id, :uuid, null: false

    add_index :registration_user_registrations, :registration_campaign_id
    add_index :registration_user_registrations, :registration_item_id
    add_index :registration_user_registrations,
              [:registration_campaign_id, :user_id, :preference_rank],
              unique: true,
              where: "(preference_rank IS NOT NULL)", name: "index_reg_user_regs_unique_ranked"
    add_index :registration_user_registrations, [:registration_campaign_id, :user_id],
              unique: true,
              where: "(preference_rank IS NULL)",
              name: "index_reg_user_regs_unique_unranked"

    # Restore Foreign Keys
    add_foreign_key :registration_items, :registration_campaigns
    add_foreign_key :registration_policies, :registration_campaigns
    add_foreign_key :registration_user_registrations, :registration_campaigns
    add_foreign_key :registration_user_registrations, :registration_items
  end

  def down
    # Remove UUID foreign keys
    remove_foreign_key :registration_items, :registration_campaigns
    remove_foreign_key :registration_policies, :registration_campaigns
    remove_foreign_key :registration_user_registrations, :registration_campaigns
    remove_foreign_key :registration_user_registrations, :registration_items

    # Registration Campaigns
    remove_column :registration_campaigns, :id
    add_column :registration_campaigns, :id, :primary_key

    # Registration Items
    remove_column :registration_items, :id
    remove_column :registration_items, :registration_campaign_id

    add_column :registration_items, :id, :primary_key
    add_column :registration_items, :registration_campaign_id, :bigint, null: false

    add_index :registration_items, :registration_campaign_id
    add_index :registration_items,
              [:registration_campaign_id, :registerable_type, :registerable_id],
              unique: true, name: "index_registration_items_uniqueness"

    # Registration Policies
    remove_column :registration_policies, :id
    remove_column :registration_policies, :registration_campaign_id

    add_column :registration_policies, :id, :primary_key
    add_column :registration_policies, :registration_campaign_id, :bigint, null: false

    add_index :registration_policies, :registration_campaign_id
    add_index :registration_policies, [:registration_campaign_id, :position],
              unique: true,
              name: "index_registration_policies_uniqueness"

    # Registration User Registrations
    remove_column :registration_user_registrations, :id
    remove_column :registration_user_registrations, :registration_campaign_id
    remove_column :registration_user_registrations, :registration_item_id

    add_column :registration_user_registrations, :id, :primary_key
    add_column :registration_user_registrations, :registration_campaign_id, :bigint, null: false
    add_column :registration_user_registrations, :registration_item_id, :bigint, null: false

    add_index :registration_user_registrations, :registration_campaign_id
    add_index :registration_user_registrations, :registration_item_id
    add_index :registration_user_registrations,
              [:registration_campaign_id, :user_id, :preference_rank],
              unique: true,
              where: "(preference_rank IS NOT NULL)",
              name: "index_reg_user_regs_unique_ranked"
    add_index :registration_user_registrations, [:registration_campaign_id, :user_id],
              unique: true, where: "(preference_rank IS NULL)",
              name: "index_reg_user_regs_unique_unranked"

    # Restore Integer Foreign Keys
    add_foreign_key :registration_items, :registration_campaigns
    add_foreign_key :registration_policies, :registration_campaigns
    add_foreign_key :registration_user_registrations, :registration_campaigns
    add_foreign_key :registration_user_registrations, :registration_items
  end
end
