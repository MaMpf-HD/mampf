# rubocop:disable Rails/
class CreateInteractions < ActiveRecord::Migration[6.0]
  def change
    create_table :interactions do |t|
      t.text :session_id
    end
  end
end
# rubocop:enable Rails/
