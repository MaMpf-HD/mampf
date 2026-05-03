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

  private

    def build_assessables_by_type
      {
        "Assignment" => lecture.assignments
                               .includes(:assessment, medium: :tags, lecture: :term)
                               .order(created_at: :desc)
      }
    end

    def all_assessables
      @all_assessables ||= assessables_by_type.values.flatten
    end
end
