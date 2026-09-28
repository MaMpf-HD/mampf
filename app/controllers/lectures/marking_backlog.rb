module Lectures
  # Counts the hand-ins still waiting for points on the sheets that are open
  # for marking, per sheet and tutorial of the tutor's own groups. It counts
  # people, since a team's hand-in is marked for each member, and only hand-ins
  # on record: a paper sheet or a test counts once somebody has recorded that
  # it arrived.
  class MarkingBacklog
    Entry = Struct.new(:assignment, :tutorial, :people, keyword_init: true)

    def initialize(lecture, tutorials:)
      @lecture = lecture
      @tutorials = tutorials
    end

    def entries
      @entries ||= begin
        by_assessment = open_assignments.index_by { |assignment| assignment.assessment.id }
        tutorials_by_id = @lecture.tutorials.index_by(&:id)
        found = counts.map do |(assessment_id, tutorial_id), people|
          Entry.new(assignment: by_assessment[assessment_id],
                    tutorial: tutorials_by_id[tutorial_id], people: people)
        end
        found.sort_by { |entry| [entry.assignment.deadline, entry.tutorial&.title.to_s] }
      end
    end

    private

      def open_assignments
        @open_assignments ||= @lecture.assignments.includes(:assessment)
                                      .select { |a| a.assessment && a.grading_open? }
      end

      def counts
        return {} if open_assignments.empty?
        return {} if @tutorials.empty?

        Assessment::Participation.pending.submitted
                                 .where(assessment_id: open_assignments.map { |a| a.assessment.id },
                                        tutorial_id: @tutorials.map(&:id))
                                 .group(:assessment_id, :tutorial_id).count
      end
  end
end
