namespace :enrollment do
  desc "Report who is enrolled without a place and campaigns that go wrong on their own; " \
       "APPLY=1 takes the former off their lectures, LECTURE_IDS=1,2 narrows it to some"
  task reconcile: :environment do
    ids = ENV["LECTURE_IDS"]&.split(",")&.map(&:to_i)
    reconciliation = Rosters::EnrollmentReconciliation.new(lecture_ids: ids)
    puts(reconciliation.report)
    next unless ENV["APPLY"] == "1"

    puts("Taken off: #{reconciliation.apply!}")
  end
end
