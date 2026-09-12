# The strip between the page and the pointing table, the same for a group's
# page and the lecture's: one line saying where the sheet stands, the filters
# into the rows, the rare actions behind one menu, and the one button that
# belongs to the table - saving every edited row at once.
class PointingToolbarComponent < ViewComponent::Base
  # The states a row can show, in the order the summary names them. Where a
  # count is zero the summary keeps quiet, except about the hand-ins.
  SUMMARY_PARTS = [:reviewed, :pending_grading, :not_submitted, :awaiting_record,
                   :exempt, :absent].freeze

  def initialize(assignment:, grading_scope:, statuses:, submissions:, tutorials: [])
    super()
    @assignment = assignment
    @grading_scope = grading_scope
    @tutorial = grading_scope if grading_scope.is_a?(Tutorial)
    @statuses = statuses
    @submissions = submissions
    @tutorials = tutorials
  end

  def summary
    counts = @statuses.tally
    handed_in = counts.fetch(:reviewed, 0) + counts.fetch(:pending_grading, 0)
    parts = [I18n.t("assessment.grading_tutorial.summary.handed_in", count: handed_in)]
    SUMMARY_PARTS.each do |status|
      next unless counts[status]&.positive?

      parts << I18n.t("assessment.grading_tutorial.summary.#{status}", count: counts[status])
    end
    parts.join(" · ")
  end

  # The filter offers the states the rows can show; a sheet collected on
  # paper has no "not submitted" row, one with files no "not yet recorded".
  def status_options
    missing = @assignment.assessment&.status_without_hand_in || :not_submitted
    [["reviewed", column_label("reviewed")],
     ["pending_grading", column_label("pending_grading")],
     [missing.to_s, column_label(missing)],
     ["exempt", column_label("exempt")]]
  end

  def tutorial_options
    @tutorials.map { |tutorial| [tutorial.id.to_s, tutorial.title] } +
      [["none", I18n.t("assessment.grading_tutorial.no_tutorial_badge")]]
  end

  def lecture_form?
    @tutorial.nil?
  end

  def can_enter_points?
    user = helpers.current_user
    user.admin? || user.can_enter_points_in?(@grading_scope)
  rescue User::IncompatibleTypeError
    false
  end

  # Downloads and uploads go per group; the lecture's table has no bundle.
  def menu?
    @tutorial.present? && (hand_in_files? || certificate_check?)
  end

  def tutor?
    @tutorial.present? && helpers.current_user.in?(@tutorial.tutors)
  end

  def certificate_check?
    Flipper.enabled?(:quiz_certificates)
  end

  def hand_in_files?
    @submissions.any?
  end

  def corrections?
    @submissions.any? { |submission| submission.correction.present? }
  end

  def grading_scope_type
    @grading_scope.class.name.downcase
  end

  private

    def column_label(status)
      I18n.t("student_performance.records.columns.#{status}")
    end
end
