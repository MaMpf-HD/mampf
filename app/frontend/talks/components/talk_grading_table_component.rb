class TalkGradingTableComponent < ViewComponent::Base
  def initialize(seminar:)
    super()
    @seminar = seminar
    @talks = seminar.talks.includes(:speakers, :assessment)
  end

  def gradable_talks
    @gradable_talks ||= @talks.select { |t| t.speakers.any? && t.assessment.present? }
  end

  def legacy_talks
    @legacy_talks ||= @talks.select { |t| t.speakers.any? && t.assessment.blank? }
  end

  def rows
    @rows ||= gradable_talks.flat_map do |talk|
      talk.speakers.filter_map { |speaker| participations_index[[talk.assessment.id, speaker.id]] }
    end
  end

  def row_statuses
    rows.map(&:display_status)
  end

  def summary
    MarkingSummaryComponent.new(statuses: row_statuses, hand_ins: false)
  end

  # A talk is graded or not; nothing marks a speaker absent or exempt.
  def status_options
    [:reviewed, :pending_grading].map do |status|
      [status.to_s, I18n.t("student_performance.records.columns.#{status}")]
    end
  end

  def layout
    @layout ||= MarkingTableLayout.for(assessable: gradable_talks.first,
                                       grading_scope: @seminar)
  end

  private

    def participations_index
      @participations_index ||= Assessment::ParticipationIndex.build(
        gradable_talks.flat_map do |talk|
          talk.speakers.map do |speaker|
            [talk.assessment, speaker]
          end
        end
      )
    end
end
