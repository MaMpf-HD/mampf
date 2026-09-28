module RecordsOffice
  # Gathers what the records office sees of one term: every lecture with its
  # groups and how full they are, and which downloads each lecture has, in a
  # fixed number of queries however many lectures the term holds. Members are
  # counted, not loaded, since a term holds thousands of them.
  class TermOverview
    GROUP_ASSOCIATIONS = [:tutorials, :talks, :cohorts, :exams].freeze
    GROUP_TYPES = { "tutorial" => Tutorial, "talk" => Talk,
                    "cohort" => Cohort, "exam" => Exam }.freeze

    # Talks are listed by their number, as the seminar lists them.
    def self.group_title(group)
      group.is_a?(Talk) ? group.to_label : group.title
    end

    def self.group_type(group)
      GROUP_TYPES.key(group.class)
    end

    def initialize(term)
      @term = term
    end

    def lectures
      return [] unless @term

      @lectures ||= Lecture.where(term: @term)
                           .includes(:course, :term, :teacher, *GROUP_ASSOCIATIONS)
                           .sort_by { |lecture| lecture.title_no_term.downcase }
    end

    def groups(lecture)
      GROUP_ASSOCIATIONS.flat_map { |association| lecture.public_send(association).to_a }
    end

    def member_count(lecture)
      member_counts.fetch(lecture.id, 0)
    end

    def roster_count(group)
      roster_counts.fetch(group.class).fetch(group.id, 0)
    end

    def grades?(lecture)
      lecture_ids_with_grades.include?(lecture.id)
    end

    def admissions?(lecture)
      lecture_ids_with_admissions.include?(lecture.id)
    end

    private

      def member_counts
        @member_counts ||= LectureMembership.where(lecture: lectures).group(:lecture_id).count
      end

      def roster_counts
        @roster_counts ||= {
          Tutorial => count_entries(TutorialMembership, :tutorial_id, Tutorial),
          Talk => count_entries(SpeakerTalkJoin, :talk_id, Talk),
          Cohort => count_entries(CohortMembership, :cohort_id, Cohort),
          Exam => count_entries(ExamRosterEntry.active, :exam_id, Exam)
        }
      end

      def count_entries(entries, column, group_class)
        ids = lectures.flat_map { |lecture| groups(lecture) }.grep(group_class).map(&:id)
        entries.where(column => ids).group(column).count
      end

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
