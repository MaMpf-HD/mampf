class CreateJoinTableAnswersOptions < ActiveRecord::Migration[7.1]
  def change
    create_join_table :vignettes_answers, :vignettes_options,
                      table_name: :vignettes_answers_options do |t|
      t.index [:vignettes_answer_id, :vignettes_option_id],
              name: "index_answers_options_on_answer_id_and_option_id"
      t.index [:vignettes_option_id, :vignettes_answer_id],
              name: "index_answers_options_on_option_id_and_answer_id"
    end
  end
end
