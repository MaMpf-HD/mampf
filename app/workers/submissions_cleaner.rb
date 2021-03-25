class SubmissionsCleaner
  include Sidekiq::Worker

  def perform
    submission_cleaner = SubmissionsCleaner.new(date: Date.today)
    submission_cleaner.clean!
  end
end