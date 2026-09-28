module RecordsOffice
  # Builds the records office's downloads for German Excel: semicolons between
  # the fields, decimal commas, and a byte order mark, without which Excel
  # reads the file as Windows-1252 and garbles every umlaut.
  module Export
    BOM = "\uFEFF".freeze
    PERSON_COLUMNS = [:last_name, :first_name, :matriculation_number, :email].freeze
    COLUMNS = {
      grades: PERSON_COLUMNS + [:kind, :title, :grade, :status],
      admissions: PERSON_COLUMNS + [:points, :maximum, :percentage, :criteria_met,
                                    :decision, :decided_by, :decided_at, :note],
      emails: PERSON_COLUMNS
    }.freeze

    # The rosterables whose members the records office can download, by the
    # name the route carries.
    GROUP_TYPES = { "tutorial" => Tutorial, "talk" => Talk,
                    "cohort" => Cohort, "exam" => Exam }.freeze

    # Lists the published results of the lecture's exams and talks; results
    # still being graded, and sheets, stay with the teachers.
    def self.grades(lecture)
      gradebooks = Assessment::Assessment.where(lecture: lecture, assessable_type: ["Exam", "Talk"])
                                         .where.not(results_published_at: nil)
      scope = Assessment::Participation.all
      with_result = scope.where.not(grade_numeric: nil).or(scope.where.not(grade_text: nil))
                         .or(scope.absent).or(scope.exempt)
      participations = scope.where(assessment: gradebooks).merge(with_result)
                            .includes(:user, assessment: :assessable)
                            .sort_by do |participation|
        [group_title(participation.assessment.assessable), *sort_key(participation.user)]
      end
      generate(:grades, participations.map { |participation| grade_row(participation) })
    end

    # Lists every admission decision of the lecture with what it rests on: the
    # points, the criteria met, who decided and why.
    def self.admissions(lecture)
      records = lecture.student_performance_records.index_by(&:user_id)
      achievements = Achievement.where(lecture: lecture).pluck(:id, :title).to_h
      rows = lecture.student_performance_certifications.includes(:user, :certified_by)
                    .sort_by { |certification| sort_key(certification.user) }
                    .map do |certification|
        person(certification.user) +
          record_fields(records[certification.user_id], achievements) +
          decision_fields(certification)
      end
      generate(:admissions, rows)
    end

    # Lists the members of one group, for the course evaluation's mailing.
    def self.emails(group)
      members = group.is_a?(Exam) ? group.users : group.members
      generate(:emails, members.sort_by { |user| sort_key(user) }.map { |user| person(user) })
    end

    # A talk may have no title of its own; its label carries the number.
    def self.group_title(group)
      group.is_a?(Talk) ? group.to_label : group.title
    end

    def self.generate(kind, rows)
      BOM + SafeCsv.generate(col_sep: ";") do |csv|
        csv << COLUMNS.fetch(kind).map { |column| I18n.t("records_office.columns.#{column}") }
        rows.each { |row| csv << row }
      end
    end
    private_class_method :generate

    def self.sort_key(user)
      [user.last_name.to_s.downcase, user.first_name.to_s.downcase, user.email]
    end
    private_class_method :sort_key

    def self.person(user)
      [user.last_name, user.first_name, user.matriculation_number, user.email]
    end
    private_class_method :person

    def self.grade_row(participation)
      assessable = participation.assessment.assessable
      kind = I18n.t("records_office.kinds.#{assessable.class.name.downcase}")
      grade = participation.grade_numeric && format("%.1f", participation.grade_numeric)
      status = if participation.absent? || participation.exempt?
        I18n.t("assessment.grading_exam.status_word.#{participation.status}")
      end
      person(participation.user) +
        [kind, group_title(assessable), grade&.tr(".", ",") || participation.grade_text, status]
    end
    private_class_method :grade_row

    def self.record_fields(record, achievements)
      return [nil] * 4 unless record

      met = record.achievements_met_ids.filter_map { |id| achievements[id] }
      [decimal(record.points_total_materialized), decimal(record.points_max_materialized),
       decimal(record.percentage_materialized), met.join(", ")]
    end
    private_class_method :record_fields

    def self.decision_fields(certification)
      decided_by = if certification.manual?
        certification.certified_by&.tutorial_name
      elsif !certification.pending?
        I18n.t("records_office.decided_by_rule")
      end
      [I18n.t("records_office.decisions.#{certification.status}"), decided_by,
       certification.certified_at && I18n.l(certification.certified_at.to_date),
       certification.note]
    end
    private_class_method :decision_fields

    def self.decimal(value)
      return if value.nil?

      value.to_d.to_s("F").delete_suffix(".0").tr(".", ",")
    end
    private_class_method :decimal
  end
end
