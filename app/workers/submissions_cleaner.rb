class SubmissionsCleaner
  include Sidekiq::Worker

  def perform
    submission_cleaner = SubmissionCleaner.new(date: Date.today)
    #submission_cleaner.clean!
  end
end