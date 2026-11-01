# TODO: Remove together with Rosters::EnrollmentReconciliation once it has run
# on production (#1408, https://github.com/MaMpf-HD/mampf/pull/1408).
namespace :enrollment do
  desc "Report who is enrolled without a place or holds a place without being enrolled, " \
       "and campaigns that go wrong on their own; APPLY=1 sets the rosters right, " \
       "LECTURE_IDS=1,2 narrows it to some"
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

    excluded, enrolled = reconciliation.apply!
    puts("Taken off: #{excluded}, enrolled: #{enrolled}")
  end
end
