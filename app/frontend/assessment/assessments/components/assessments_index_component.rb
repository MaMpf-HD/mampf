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
               .includes(:assessment, medium: :tags, lecture: :term)
               .order(created_at: :desc)
      else
        []
      end
    end

    def all_talks
      @all_talks ||= lecture.talks
                            .includes(:assessment, :speakers, lecture: :term)
                            .order(:position)
    end

    def all_assessables
      @all_assessables ||= assessables_by_type.values.flatten
    end
end
