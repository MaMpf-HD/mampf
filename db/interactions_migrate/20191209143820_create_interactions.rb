class CreateInteractions < ActiveRecord::Migration[6.0]
  def change
    create_table :interactions do |t| # rubocop:todo Rails/CreateTableWithTimestamps
      t.text :session_id
    end
  end
end
