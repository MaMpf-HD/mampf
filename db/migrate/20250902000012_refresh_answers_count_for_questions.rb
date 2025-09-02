class RefreshAnswersCountForQuestions < ActiveRecord::Migration[8.0]
  def up
    say_with_time "Resetting answers_count for all Questions" do
      Question.find_each do |q|
        Question.reset_counters(q.id, :answers, touch: true)
      end
    end
  end

  def down
  end
end
