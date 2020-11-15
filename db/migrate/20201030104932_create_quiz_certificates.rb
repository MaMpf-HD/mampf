class CreateQuizCertificates < ActiveRecord::Migration[6.0]
  def up
    create_table :quiz_certificates, id: :uuid do |t|
      t.references :quiz, null: false, foreign_key: { to_table: :media }
      t.references :user, null: true, foreign_key: true
      t.text :code

      t.timestamps
    end
  end

  def down
    drop_table :quiz_certificates
  end
end
