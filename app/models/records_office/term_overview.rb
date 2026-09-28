module RecordsOffice
  # Gathers what the records office sees of one term: every lecture with its
  # groups and how full they are, and which downloads each lecture has, in a
  # fixed number of queries however many lectures the term holds.
  class TermOverview
    GROUP_ASSOCIATIONS = { tutorials: :tutorial_memberships, talks: :speaker_talk_joins,
                           cohorts: :cohort_memberships, exams: :exam_roster_entries }.freeze

    def initialize(term)
      @term = term
    end

    def lectures
      return [] unless @term

      @lectures ||= Lecture.where(term: @term)
                           .includes(:course, :term, :teacher, :lecture_memberships,
                                     **GROUP_ASSOCIATIONS)
                           .sort_by { |lecture| lecture.title_no_term.downcase }
    end

    # Tutorials, talks, cohorts and exams, in that order.
    def groups(lecture)
      GROUP_ASSOCIATIONS.keys.flat_map { |association| lecture.public_send(association).to_a }
    end

    def grades?(lecture)
      lecture_ids_with_grades.include?(lecture.id)
    end

    def admissions?(lecture)
      lecture_ids_with_admissions.include?(lecture.id)
    end

    private

      def lecture_ids_with_grades
        @lecture_ids_with_grades ||=
          Assessment::Assessment.with_published_results.where(lecture: lectures)
                                .distinct.pluck(:lecture_id).to_set
      end

      def lecture_ids_with_admissions
        @lecture_ids_with_admissions ||=
          StudentPerformance::Certification.where(lecture: lectures)
                                           .distinct.pluck(:lecture_id).to_set
      end
  end
end
