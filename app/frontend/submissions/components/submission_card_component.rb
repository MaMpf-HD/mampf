# The card for a sheet that can still be handed in: what it is, when it is due,
# what the reader has put there, and every action they can still take on it.
#
# One card is one Turbo Frame. Handing in, replacing, inviting, joining and
# leaving all change this sheet and nothing else - the history list holds only
# sheets that are closed - so every one of them is answered by re-rendering this
# frame, and none of them needs a Turbo Stream.
class SubmissionCardComponent < ViewComponent::Base
  include ActiveSupport::NumberHelper

  # Named here rather than spelled out at each end: a target that stops matching
  # updates nothing and reports nothing.
  def self.frame_id(assignment)
    ActionView::RecordIdentifier.dom_id(assignment, :submission_card)
  end

  attr_reader :sheet, :invites, :partners, :error

  delegate :assignment, :submission, to: :sheet

  # `error` is for the one refusal that has nowhere else to go: leaving a team of
  # one. It belongs on the card, not in a page-wide flash the reader has to look
  # away to find.
  def initialize(sheet:, invites: [], partners: [], error: nil)
    super()
    @sheet = sheet
    @invites = invites
    @partners = partners
    @error = error
  end

  def frame_id
    self.class.frame_id(assignment)
  end

  # With several sheets open there are several cards; naming each one after its
  # sheet is what tells them apart for anybody not looking at the screen.
  def heading_id
    "#{frame_id}_heading"
  end

  def due_line
    t("submission.hub.card.due", time: l(assignment.deadline,
                                         format: :submission_deadline))
  end

  # File type, how long is left, and what the sheet is worth - the three things
  # that decide whether to start on it now.
  def meta_parts
    parts = [assignment.accepted_file_type.delete_prefix(".").upcase]
    parts << time_left if assignment.semiactive?
    parts << worth if sheet.tasks.any?
    parts.compact
  end

  def handed_in?
    submission&.manuscript.present?
  end

  def file_name
    submission&.manuscript_filename
  end

  def file_details
    size = number_to_human_size(submission.manuscript_size)
    at = submission.last_modification_by_users_at || submission.created_at
    "#{size} · #{l(at, format: :short)}"
  end

  def correction_name
    submission&.correction_filename
  end

  # Without a group there is nobody to hand in to, so the card says that instead
  # of offering buttons that would fail.
  def may_start?
    !roster_eligible? || helpers.rostered_tutorial_for(assignment.lecture).present?
  end

  def editable?
    submission.present? && !submission.not_updatable?
  end

  def invitable?
    return false unless submission && assignment.active?
    return false if invitable_partners.empty?

    max = assignment.lecture.submission_max_team_size
    max.nil? || submission.users.size < max
  end

  def alone?
    submission.present? && submission.users.size == 1
  end

  def partner_names
    return [] unless submission

    sheet.partners.map(&:tutorial_name)
  end

  def invited_names
    return [] unless submission && assignment.active?

    submission.invited_users.map(&:tutorial_name)
  end

  # The code is what a partner joins with, so it is worth showing only while
  # joining is still possible.
  def token
    submission.token if submission && assignment.semiactive?
  end

  def tutorial_name
    submission&.tutorial&.title_with_tutors
  end

  # Everybody the reader could still add to this team: what the loader fetched
  # once for the page, minus whoever is already on it.
  def invitable_partners
    @invitable_partners ||= partners - submission.users.to_a
  end

  private

    def roster_eligible?
      helpers.enabled_roster_for_lecture?(assignment.lecture)
    end

    def time_left
      t("submission.hub.card.in_time",
        time: distance_of_time_in_words(Time.zone.now, assignment.deadline))
    end

    def worth
      t("submission.hub.card.worth", count: sheet.tasks.size,
                                     points: number_to_rounded(
                                       sheet.max_points || 0, precision: 2,
                                                              strip_insignificant_zeros: true
                                     ))
    end
end
