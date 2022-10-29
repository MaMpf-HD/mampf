class DropAdditionalAndDisabledTagsTables < ActiveRecord::Migration[5.2]
  def up
    drop_table :lecture_tag_additional_joins
    drop_table :lecture_tag_disabled_joins
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
