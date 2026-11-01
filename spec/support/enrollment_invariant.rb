# Fails a request that breaks the enrollment rules (see
# Rosters::Rosterable#enrolls_in_lecture?). Only states the request itself
# creates count, so a spec may set up a broken state first. Tag a spec with
# skip_enrollment_invariant to opt out.
module EnrollmentInvariant
  class ViolationError < StandardError; end

  # Returns [[kind, lecture_id, user_id], ...] for all lectures. Bypasses Active
  # Record's instrumentation, so specs that count a request's queries don't
  # count these.
  def self.violations
    ids(Lecture.select(:id)).flat_map do |id|
      violations_in(Lecture.instantiate("id" => id))
    end
  end

  def self.violations_in(lecture)
    members = lecture.lecture_memberships.select(:user_id)
    queries = lecture.enrolling_memberships
    without_place = queries.reduce(lecture.lecture_memberships) do |scope, query|
      scope.where.not(user_id: query)
    end
    unenrolled = queries.map { |query| User.where(id: query).where.not(id: members) }

    ids(without_place.select(:user_id)).map { |id| [:without_place, lecture.id, id] } +
      unenrolled.flat_map { |scope| ids(scope.select(:id)) }.uniq
                .map { |id| [:place_without_membership, lecture.id, id] }
  end

  def self.ids(query)
    ActiveRecord::Base.connection.raw_connection.exec(query.to_sql).column_values(0).map(&:to_i)
  end

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
