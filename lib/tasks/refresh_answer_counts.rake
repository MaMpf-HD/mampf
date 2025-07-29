namespace :data do
  desc "Reset the answers_count for all existing Question media."
  task reset_answers_count: :environment do
    puts "Starting to reset answers_count for all Questions..."
    Question.find_each do |q|
      Question.reset_counters(q.id, :answers)
    end
    puts "Finished resetting answers_count."
  end
end
