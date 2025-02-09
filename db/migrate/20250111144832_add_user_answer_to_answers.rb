class AddUserAnswerToAnswers < ActiveRecord::Migration[7.1]
  def change
    add_reference :vignettes_answers, :vignettes_user_answer, null: false, foreign_key: true
  end
end
