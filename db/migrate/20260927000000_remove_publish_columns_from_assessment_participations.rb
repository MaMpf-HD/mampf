# The results of an assessment are published for all its participants at
# once, on the assessment; these per-row flags were never read.
class RemovePublishColumnsFromAssessmentParticipations < ActiveRecord::Migration[8.0]
  def change
    change_table :assessment_participations, bulk: true do |t|
      t.remove :results_published_at, type: :datetime
      t.remove :published, type: :boolean, default: false, null: false
      t.remove :locked, type: :boolean, default: false, null: false
    end
  end
end
