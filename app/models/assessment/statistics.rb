module Assessment
  # The figures a teacher reads off one assessment's marks beyond the spread
  # of the points (see DistributionAnalysisComponent): per task, per program
  # and per tutorial, and for a graded assessment the grades. Points count
  # only rows marked in full, so that a sheet half way through marking does
  # not pull the averages down.
  class Statistics
    Figures = Struct.new(:number, :mean, :median, keyword_init: true)
    TaskRow = Struct.new(:task, :figures, :full_share, :zero_share, keyword_init: true)
    GroupRow = Struct.new(:label, :people, :figures, :grades, keyword_init: true)
    GradeFigures = Struct.new(:number, :mean, :pass_share, keyword_init: true)

    PASSING = GradeScheme::PASSING_GRADES.max

    attr_reader :assessment

    def initialize(assessment)
      @assessment = assessment
    end

    def self.figures(values)
      return Figures.new(number: 0) if values.empty?

      sorted = values.map(&:to_f).sort
      Figures.new(number: sorted.size, mean: sorted.sum / sorted.size,
                  median: median_of(sorted))
    end

    def self.median_of(sorted)
      middle = sorted.size / 2
      sorted.size.odd? ? sorted[middle] : (sorted[middle - 1] + sorted[middle]) / 2
    end
    private_class_method :median_of

    def participations
      @participations ||= assessment.assessment_participations
                                    .includes(:tutorial, :task_points,
                                              user: User::PROGRAM_PRELOAD).to_a
    end

    def marked
      @marked ||= participations.select { |row| row.reviewed? && row.points_total }
    end

    def graded
      @graded ||= participations.select(&:grade_numeric)
    end

    def counts
      @counts ||= {
        total: participations.size,
        handed_in: participations.count(&:submitted_at),
        marked: marked.size,
        absent: participations.count(&:absent?),
        exempt: participations.count(&:exempt?)
      }
    end

    def max_points
      @max_points ||= tasks.sum { |task| task.max_points.to_f }
    end

    def tasks
      @tasks ||= assessment.tasks.order(:position).to_a
    end

    def task_rows
      tasks.map do |task|
        values = marked.filter_map do |row|
          row.task_points.find { |point| point.task_id == task.id }&.points
        end
        max = task.max_points.to_f
        TaskRow.new(task: task, figures: self.class.figures(values),
                    full_share: share(values) { |value| max.positive? && value >= max },
                    zero_share: share(values) { |value| value.to_f.zero? })
      end
    end

    def grades
      @grades ||= grade_figures(graded)
    end

    def grade_distribution
      GradeScheme::PASSING_GRADES.sort.push(5.0).map do |grade|
        [grade, graded.count { |row| row.grade_numeric == grade.to_d }]
      end
    end

    def program_rows
      group_rows(participations.group_by { |row| row.user.program }) do |program|
        program&.name_with_subject
      end
    end

    def tutorial_rows
      return [] if participations.none?(&:tutorial)

      group_rows(participations.group_by(&:tutorial)) { |tutorial| tutorial&.title }
    end

    private

      def share(values, &)
        return if values.empty?

        values.count(&).to_f / values.size
      end

      def grade_figures(rows)
        return GradeFigures.new(number: 0) if rows.empty?

        values = rows.map { |row| row.grade_numeric.to_f }
        GradeFigures.new(number: values.size, mean: values.sum / values.size,
                         pass_share: values.count { |value| value <= PASSING }.to_f / values.size)
      end

      def group_rows(groups)
        marked_ids = marked.to_set(&:id)
        rows = groups.map do |key, members|
          scored = members.select { |row| marked_ids.include?(row.id) }
          GroupRow.new(label: yield(key), people: members.size,
                       figures: self.class.figures(scored.map(&:points_total)),
                       grades: grade_figures(members.select(&:grade_numeric)))
        end
        rows.sort_by { |row| [row.label.nil? ? 1 : 0, row.label.to_s.downcase] }
      end
  end
end
