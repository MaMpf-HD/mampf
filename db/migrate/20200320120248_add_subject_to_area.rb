class AddSubjectToArea < ActiveRecord::Migration[6.0]
  def change
    add_reference :areas, :subject, foreign_key: true
  end
end
