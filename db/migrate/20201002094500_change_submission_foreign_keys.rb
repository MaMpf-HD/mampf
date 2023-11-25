class ChangeSubmissionForeignKeys < ActiveRecord::Migration[6.0]
  def up
    remove_index :user_submission_joins,
                 name: "index_user_submission_joins_on_submission_id"
    id_to_uuid("user_submission_joins", "submission", "submission")
    add_index :user_submission_joins, :submission_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  def id_to_uuid(table_name, relation_name, relation_class)
    table_name = table_name.to_sym
    klass = table_name.to_s.classify.constantize
    relation_klass = relation_class.to_s.classify.constantize
    foreign_key = "#{relation_name}_id".to_sym
    new_foreign_key = "#{relation_name}_uuid".to_sym

    add_column table_name, new_foreign_key, :uuid

    klass.where.not(foreign_key => nil).each do |record|
      next unless associated_record = relation_klass.find_by(id: record.send(foreign_key))

      # rubocop:todo Rails/SkipsModelValidations
      record.update_column(new_foreign_key, associated_record.uuid)
      # rubocop:enable Rails/SkipsModelValidations
    end

    remove_column table_name, foreign_key
    rename_column table_name, new_foreign_key, foreign_key
  end
end
