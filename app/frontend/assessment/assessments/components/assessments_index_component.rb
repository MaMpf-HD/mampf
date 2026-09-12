class AssessmentsIndexComponent < ViewComponent::Base
  def initialize(lecture:)
    super()
    @lecture = lecture
  end

  attr_reader :lecture

  def assessables_by_type
    @assessables_by_type ||= build_assessables_by_type
  end

  def with_assessment
    @with_assessment ||= all_assessables.select(&:assessment)
  end

  def legacy
    @legacy ||= all_assessables.reject(&:assessment)
  end

  def legacy_by_type
    @legacy_by_type ||= legacy.group_by { |a| a.class.name }
  end

  # Both directions have consequences, so both are asked about: the tick sets
  # the rule judging, taking it back puts every verdict to deferred again.
  # Taking it back on top of computed decisions has one more thing to say, and
  # it is the only dialog with a third button.
  def confirmation
    return :close unless lecture.assignments_complete?
    return :reopen if computed_decisions_count.positive?

    :open
  end

  def confirmation_title
    t("assessment.assignments_complete.#{confirmation}_dialog.title")
  end

  def confirmation_body
    if confirmation == :reopen
      return t("assessment.assignments_complete.reopen_dialog.body",
               count: computed_decisions_count)
    end

    t("assessment.assignments_complete.#{confirmation}_dialog.body")
  end

  def confirmation_button
    t("assessment.assignments_complete.#{confirmation}_dialog.confirm")
  end

  def computed_decisions_count
    @computed_decisions_count ||= lecture.student_performance_certifications
                                         .computed
                                         .decided
                                         .count
  end

  private

    def build_assessables_by_type
      result = {}
      lecture.supported_assessable_types.each do |type|
        result[type] = fetch_for_type(type)
      end
      result
    end

    def fetch_for_type(type)
      case type
      when "Talk"
        all_talks.select { |t| t.speakers.any? }
      when "Assignment"
        lecture.assignments
               .includes({ assessment: :assessment_participations },
                         { medium: :tags },
                         { lecture: :term })
               .order(created_at: :desc)
      else
        []
      end
    end

    def all_talks
      @all_talks ||= lecture.talks
                            .includes({ assessment: :assessment_participations },
                                      :speakers,
                                      { lecture: :term })
                            .order(:position)
    end

    def all_assessables
      @all_assessables ||= assessables_by_type.values.flatten
    end
end
