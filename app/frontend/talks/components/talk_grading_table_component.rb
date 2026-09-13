class TalkGradingTableComponent < ViewComponent::Base
  def initialize(seminar:)
    super()
    @seminar = seminar
    @talks = seminar.talks.includes(:speakers, :assessment)
  end

  def grading_enabled?
    true
  end

  def gradable_talks
    @gradable_talks ||= @talks.select { |t| t.speakers.any? && t.assessment.present? }
  end

  def legacy_talks
    @legacy_talks ||= @talks.select { |t| t.speakers.any? && t.assessment.blank? }
  end

  def possible_statuses
    ["pending", "reviewed"]
  end

  def participation_for(assessment, user)
    return if assessment.nil? || user.nil?

    participations_index[[assessment.id, user.id]]
  end

  def layout
    @layout ||= PointingTableLayout.for(assessable: gradable_talks.first,
                                        grading_scope: @seminar)
  end

  private

    def participations_index
      @participations_index ||= Assessment::TalkGraderService.init_participations(
        gradable_talks.flat_map do |talk|
          talk.speakers.map do |speaker|
            [talk.assessment, speaker]
          end
        end
      )
    end
end
