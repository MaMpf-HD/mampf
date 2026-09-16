# The strip above the pointing table, the same on a group's page and in the
# lecture's dashboard: summary, filters, the rare actions and saving.
class PointingToolbarComponent < ViewComponent::Base
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
    PointingSummaryComponent.new(statuses: @statuses, hand_ins: !@assignment.kind_test?)
  end

  def status_options
    missing = @assignment.assessment&.status_without_hand_in || :not_submitted
    options = [["reviewed", column_label("reviewed")],
               ["pending_grading", column_label("pending_grading")],
               [missing.to_s, column_label(missing)]]
    options << ["absent", column_label("absent")] if @assignment.kind_test?
    options << ["exempt", column_label("exempt")]
  end

  def tutorial_options
    @tutorials.map { |tutorial| [tutorial.id.to_s, tutorial.title] } +
      [["none", I18n.t("assessment.grading_tutorial.no_tutorial_badge")]]
  end

  def lecture_form?
    @tutorial.nil?
  end

  # A sheet from before there were points has files to download but no
  # states, no points and nothing to record.
  def grading_enabled?
    @assignment.assessable?
  end

  def upload_open?
    !@assignment.active?
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
