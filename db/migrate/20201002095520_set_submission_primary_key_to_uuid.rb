class SetSubmissionPrimaryKeyToUuid < ActiveRecord::Migration[6.0]
  def up
    rename_column :submissions, :id, :integer_id
    rename_column :submissions, :uuid, :id # rubocop:todo Rails/DangerousColumnNames
    execute "ALTER TABLE submissions drop constraint submissions_pkey;"
    execute "ALTER TABLE submissions ADD PRIMARY KEY (id);"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
