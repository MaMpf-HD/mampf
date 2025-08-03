class AddIndexToProbesOnAttemptTokenAndCorrect < ActiveRecord::Migration[8.0]
  def change
    add_index :probes, [:attempt_token, :correct]
  end
end
