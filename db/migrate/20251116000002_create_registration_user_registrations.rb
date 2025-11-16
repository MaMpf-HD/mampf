class CreateRegistrationUserRegistrations < ActiveRecord::Migration[8.0]
  def change
    create_table :registration_user_registrations do |t|
      t.references :registration_campaign,
                   null: false,
                   foreign_key: true,
                   index: true
      t.references :user, null: false, foreign_key: true, index: true
      t.references :registration_item,
                   null: true,
                   foreign_key: true,
                   index: true
      t.integer :preference_rank
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :registration_user_registrations,
              [:registration_campaign_id, :user_id],
              unique: true,
              where: "preference_rank IS NULL",
              name: "index_reg_user_regs_unique_unranked"

    add_index :registration_user_registrations,
              [:registration_campaign_id, :user_id, :preference_rank],
              unique: true,
              where: "preference_rank IS NOT NULL",
              name: "index_reg_user_regs_unique_ranked"
    add_index :registration_user_registrations, :status
  end
end
