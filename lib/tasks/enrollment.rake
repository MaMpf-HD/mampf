namespace :enrollment do
  desc "Report who is enrolled without a place and campaigns that go wrong on their own; " \
       "APPLY=1 takes the former off their lectures, LECTURE_IDS=1,2 narrows it to some. " \
       "Run APPLY=1 while nobody can use the app: it takes no locks"
  task reconcile: :environment do
    ids = ENV["LECTURE_IDS"]&.split(",")&.map { |id| Integer(id.strip) }
    if ids
      unknown = ids - Lecture.where(id: ids).pluck(:id)
      abort("LECTURE_IDS names no lecture") if ids.empty?
      abort("No lectures with the ids #{unknown.join(", ")}") if unknown.any?
      Lecture.where(id: ids).order(:id).each do |lecture|
        puts("Lecture #{lecture.id} #{lecture.title_term_info_no_type}")
      end
    end
    reconciliation = Rosters::EnrollmentReconciliation.new(lecture_ids: ids)
    puts(reconciliation.report)
    next unless ENV["APPLY"] == "1"

    puts("Taken off: #{reconciliation.apply!}")
  end
end
