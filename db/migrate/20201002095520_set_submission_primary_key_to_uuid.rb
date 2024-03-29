# rubocop:disable Rails/
class SetSubmissionPrimaryKeyToUuid < ActiveRecord::Migration[6.0]
  def up
    rename_column :submissions, :id, :integer_id
    rename_column :submissions, :uuid, :id
    execute "ALTER TABLE submissions drop constraint submissions_pkey;"
    execute "ALTER TABLE submissions ADD PRIMARY KEY (id);"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
# rubocop:enable Rails/
