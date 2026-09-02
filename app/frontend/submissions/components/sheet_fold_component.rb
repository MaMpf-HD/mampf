# The row continued, over the full width: what the tutor wrote per problem on
# the left, the files and who handed them in on the right. Both halves read only
# what the loader already put into the sheet - opening a row must not cost a
# query, which is also why the fold is rendered with the row rather than fetched
# when it opens.
class SheetFoldComponent < ViewComponent::Base
  include ActiveSupport::NumberHelper

  # Where the left half has numbers rather than a sentence.
  ENTERED_STATES = [:marked, :partially_marked].freeze

  # Why there is nothing to show per problem. Every state not named here has
  # simply not been marked yet.
  MISSING_REASONS = {
    no_points: "legacy",
    exempt: "exempt",
    absent: "zero",
    missed: "zero",
    not_recorded: "zero",
    rejected: "zero",
    correction_uploaded: "on_the_correction"
  }.freeze

  attr_reader :sheet

  delegate :submission, :tasks, to: :sheet

  def initialize(sheet:)
    super()
    @sheet = sheet
  end

  def state
    @state ||= sheet.state
  end

  def points_entered?
    state.in?(ENTERED_STATES)
  end

  def missing_reason
    key = MISSING_REASONS.fetch(state, "nothing_yet")
    t("submission.hub.fold.no_points.#{key}",
      max: format_number(sheet.max_points))
  end

  def task_label(task, index)
    task.description.presence ||
      t("submission.hub.fold.problem", number: index + 1)
  end

  def task_points(task)
    format_number(sheet.points_for(task))
  end

  def task_max_points(task)
    format_number(task.max_points)
  end

  def task_reader_label(task)
    t("submission.hub.points_reader", points: task_points(task),
                                      max: task_max_points(task))
  end

  # Capped rather than proportional: four problems compare better against a
  # short bar than a long one, and a wide bar reads as a figure of its own.
  def task_bar_percentage(task)
    max = task.max_points
    return if max.nil? || max.zero?

    [(sheet.points_for(task).to_f / max * 100).round(2), 100].min
  end

  def correction_filename
    submission&.correction_filename
  end

  def manuscript_filename
    submission&.manuscript_filename
  end

  # The correction has no time of its own to show: `Sheet#marked_at` is when the
  # points were typed, which is a different event from the scan being uploaded -
  # often days apart - and the upload has no timestamp until `corrected_at`
  # arrives. When it does, this is where it goes.
  def handed_in_at
    at = submission && (submission.last_modification_by_users_at ||
                        submission.created_at)
    return unless at

    l(at, format: :long)
  end

  # Two links, often the same filename: what tells them apart is the word in
  # front, and that word has to be in the link's own name as well.
  def manuscript_reader_label
    "#{t("submission.hub.fold.handed_in_label")}: #{manuscript_filename}"
  end

  def correction_reader_label
    "#{t("submission.hub.fold.correction_label")}: #{correction_filename}"
  end

  # One submission, two people, two numbers - the team hands in together and is
  # marked apart, and the reader should not read the total as the team's.
  def team_line
    names = sheet.partners.map(&:tutorial_name)
    return if names.empty?

    if points_entered?
      t("submission.hub.fold.team_with_points", names: names.to_sentence,
                                                points: format_number(sheet.points))
    else
      t("submission.hub.fold.team", names: names.to_sentence)
    end
  end

  private

    def format_number(value)
      number_to_rounded(value || 0, precision: 2,
                                    strip_insignificant_zeros: true)
    end
end
