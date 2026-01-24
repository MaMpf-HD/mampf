class RosterSupersetCheckerJob
  include Sidekiq::Worker

  sidekiq_options queue: :default,
                  retry: false,
                  backtrace: true,
                  dead: true

  def perform
    Rosters::RosterSupersetChecker.new.check_all_lectures!
  end
end
