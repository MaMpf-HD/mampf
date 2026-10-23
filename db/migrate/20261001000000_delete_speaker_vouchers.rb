# Vouchers no longer know a speaker role (3), so neither these vouchers nor
# the notifications about their redemptions could be read any more. Speakers
# stay on their talks; only the record of how they got there goes.
class DeleteSpeakerVouchers < ActiveRecord::Migration[8.0]
  def up
    execute(<<~SQL.squish)
      DELETE FROM notifications
      WHERE notifiable_type = 'Redemption'
        AND notifiable_id IN (#{speaker_redemption_ids})
    SQL
    execute("DELETE FROM claims WHERE redemption_id IN (#{speaker_redemption_ids})")
    execute("DELETE FROM redemptions WHERE id IN (#{speaker_redemption_ids})")
    execute("DELETE FROM vouchers WHERE role = 3")
  end

  def down
    raise(ActiveRecord::IrreversibleMigration)
  end

  private

    def speaker_redemption_ids
      "SELECT redemptions.id FROM redemptions " \
        "JOIN vouchers ON vouchers.id = redemptions.voucher_id WHERE vouchers.role = 3"
    end
end
