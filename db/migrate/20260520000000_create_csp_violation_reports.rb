class CreateCspViolationReports < ActiveRecord::Migration[8.0]
  def change
    create_table :csp_violation_reports do |t|
      t.text :document_uri
      t.text :referrer
      t.string :violated_directive
      t.string :effective_directive
      t.text :original_policy
      t.string :disposition
      t.text :blocked_uri
      t.integer :status_code
      t.text :source_file
      t.integer :line_number
      t.integer :column_number
      t.text :script_sample
      t.string :ip_address
      t.text :user_agent
      t.jsonb :raw_report, null: false, default: {}

      t.timestamps
    end

    add_index :csp_violation_reports, :created_at
    add_index :csp_violation_reports, :effective_directive
  end
end
