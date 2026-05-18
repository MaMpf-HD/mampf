class AddCompositeIndexToTerms < ActiveRecord::Migration[8.0]
  def change
    add_index :terms, [:year, :season]
  end
end
