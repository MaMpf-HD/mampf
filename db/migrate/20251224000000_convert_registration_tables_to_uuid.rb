class ConvertRegistrationTablesToUuid < ActiveRecord::Migration[8.0]
  def up
    # 1. Remove existing foreign keys to avoid dependency issues during column removal
    remove_foreign_key :registration_items, :registration_campaigns
    remove_foreign_key :registration_policies, :registration_campaigns
    remove_foreign_key :registration_user_registrations, :registration_campaigns
    remove_foreign_key :registration_user_registrations, :registration_items

    # 2. Registration Campaigns
    remove_column :registration_campaigns, :id
    add_column :registration_campaigns, :id, :uuid, default: "gen_random_uuid()",
                                                    primary_key: true

    # 3. Registration Items
    remove_column :registration_items, :id
    remove_column :registration_items, :registration_campaign_id

    add_column :registration_items, :id, :uuid, default: "gen_random_uuid()",
                                                primary_key: true
    add_column :registration_items, :registration_campaign_id, :uuid, null: false

    add_index :registration_items, :registration_campaign_id
    add_index :registration_items,
              [:registration_campaign_id, :registerable_type, :registerable_id],
              unique: true, name: "index_registration_items_uniqueness"

    # 4. Registration Policies
    remove_column :registration_policies, :id
    remove_column :registration_policies, :registration_campaign_id

    add_column :registration_policies, :id, :uuid, default: "gen_random_uuid()", primary_key: true
    add_column :registration_policies, :registration_campaign_id, :uuid, null: false

    add_index :registration_policies, :registration_campaign_id
    add_index :registration_policies, [:registration_campaign_id, :position],
              unique: true,
              name: "index_registration_policies_uniqueness"

    # 5. Registration User Registrations
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

    # 6. Restore Foreign Keys
    add_foreign_key :registration_items, :registration_campaigns
    add_foreign_key :registration_policies, :registration_campaigns
    add_foreign_key :registration_user_registrations, :registration_campaigns
    add_foreign_key :registration_user_registrations, :registration_items
  end

  def down
    # 1. Remove UUID foreign keys
    remove_foreign_key :registration_items, :registration_campaigns
    remove_foreign_key :registration_policies, :registration_campaigns
    remove_foreign_key :registration_user_registrations, :registration_campaigns
    remove_foreign_key :registration_user_registrations, :registration_items

    # 2. Registration Campaigns
    remove_column :registration_campaigns, :id
    add_column :registration_campaigns, :id, :bigint, primary_key: true

    # 3. Registration Items
    remove_column :registration_items, :id
    remove_column :registration_items, :registration_campaign_id

    add_column :registration_items, :id, :bigint, primary_key: true
    add_column :registration_items, :registration_campaign_id, :bigint, null: false

    add_index :registration_items, :registration_campaign_id
    add_index :registration_items,
              [:registration_campaign_id, :registerable_type, :registerable_id],
              unique: true, name: "index_registration_items_uniqueness"

    # 4. Registration Policies
    remove_column :registration_policies, :id
    remove_column :registration_policies, :registration_campaign_id

    add_column :registration_policies, :id, :bigint, primary_key: true
    add_column :registration_policies, :registration_campaign_id, :bigint, null: false

    add_index :registration_policies, :registration_campaign_id
    add_index :registration_policies, [:registration_campaign_id, :position],
              unique: true,
              name: "index_registration_policies_uniqueness"

    # 5. Registration User Registrations
    remove_column :registration_user_registrations, :id
    remove_column :registration_user_registrations, :registration_campaign_id
    remove_column :registration_user_registrations, :registration_item_id

    add_column :registration_user_registrations, :id, :bigint, primary_key: true
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

    # 6. Restore Integer Foreign Keys
    add_foreign_key :registration_items, :registration_campaigns
    add_foreign_key :registration_policies, :registration_campaigns
    add_foreign_key :registration_user_registrations, :registration_campaigns
    add_foreign_key :registration_user_registrations, :registration_items
  end
end
