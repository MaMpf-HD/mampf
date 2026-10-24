# Fails a request that leaves the rosters against the rules of enrollment
# (see Rosters::Rosterable#place?). Only what the request changes counts, so a
# spec may build such a state first; skip_enrollment_invariant opts out.
module EnrollmentInvariant
  class ViolationError < StandardError; end

  # Returns [[kind, lecture_id, user_id], ...] across every lecture. Runs
  # past Active Record's instrumentation, so that specs counting a request's
  # queries do not count these.
  def self.violations
    ids("SELECT id FROM lectures").flat_map do |id|
      violations_in(Lecture.instantiate("id" => id))
    end
  end

  def self.violations_in(lecture)
    members = lecture.lecture_memberships.select(:user_id)
    queries = lecture.place_user_id_queries
    without_place = queries.reduce(lecture.lecture_memberships) do |scope, query|
      scope.where.not(user_id: query)
    end
    unenrolled = queries.map { |query| User.where(id: query).where.not(id: members) }
    strangers = ExamRosterEntry.active.where(exam: lecture.exams).where.not(user_id: members)

    ids(without_place.select(:user_id)).map { |id| [:without_place, lecture.id, id] } +
      unenrolled.flat_map { |scope| ids(scope.select(:id)) }.uniq
                .map { |id| [:place_without_membership, lecture.id, id] } +
      ids(strangers.select(:user_id)).map { |id| [:exam_without_membership, lecture.id, id] }
  end

  def self.ids(query)
    sql = query.is_a?(String) ? query : query.to_sql
    ActiveRecord::Base.connection.raw_connection.exec(sql).column_values(0).map(&:to_i)
  end

  # Wraps each request of an integration session.
  module SessionCheck
    def process(...)
      return super unless EnrollmentInvariant.enabled

      before = EnrollmentInvariant.violations
      result = super
      added = EnrollmentInvariant.violations - before
      raise(ViolationError, "The request broke the rules of enrollment: #{added}") if added.any?

      result
    end
  end

  mattr_accessor :enabled, default: false
end

ActionDispatch::Integration::Session.prepend(EnrollmentInvariant::SessionCheck)

RSpec.configure do |config|
  config.around(type: :request) do |example|
    EnrollmentInvariant.enabled = !example.metadata[:skip_enrollment_invariant]
    example.run
  ensure
    EnrollmentInvariant.enabled = false
  end
end
