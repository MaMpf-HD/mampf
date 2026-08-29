class OneAnswerPerSlideAndRun < ActiveRecord::Migration[8.0]
  # Within one run through a vignette a slide is answered once. Answering the
  # same vignette again under the same code stays possible -- refusing that
  # would disclose that something is already stored under it -- but those are
  # separate runs and so separate rows.
  def change
    add_index :vignettes_answers, [:vignettes_user_answer_id, :vignettes_slide_id],
              unique: true, name: "index_vignettes_answers_on_run_and_slide"
  end
end
