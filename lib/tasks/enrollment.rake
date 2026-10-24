namespace :enrollment do
  desc "Report who is enrolled without a place and campaigns that go wrong on their own; " \
       "APPLY=1 takes the former off their lectures"
  task reconcile: :environment do
    reconciliation = Rosters::EnrollmentReconciliation.new
    puts(reconciliation.report)
    next unless ENV["APPLY"] == "1"

    puts("Taken off: #{reconciliation.apply!}")
  end
end
