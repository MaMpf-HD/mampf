namespace :cleanup do
  desc "Destroy expired random quizzes"
  task destroy_random_quizzes: :environment do
    Quiz.expired.destroy_all
  end
end
