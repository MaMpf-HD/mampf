class LeaveLectureComponent < ViewComponent::Base
  def self.dialog_id(lecture)
    "leave-lecture-dialog-#{lecture.id}"
  end

  def initialize(lecture:, leave:)
    super()
    @lecture = lecture
    @leave = leave
  end

  def render?
    @leave.participating?
  end

  delegate :blockers, :confirmation_code, to: :@leave

  def dialog_id
    self.class.dialog_id(@lecture)
  end

  # Named after the dialog, which is named after its lecture, so that the
  # label finds its own field.
  def confirmation_id
    "#{dialog_id}-confirmation"
  end

  def contact?
    blockers.any?(&:contact)
  end

  def consequences
    [groups_consequence, campaigns_consequence, admission_consequence,
     points_consequence, dashboard_consequence,
     t("lecture_home.leave.consequences.rejoin")].compact
  end

  private

    def groups_consequence
      return if @leave.groups.empty?

      t("lecture_home.leave.consequences.groups",
        groups: @leave.groups.map { |group| Rosters::LectureLeave.label(group) }
                      .to_sentence)
    end

    def campaigns_consequence
      return if @leave.campaigns_to_withdraw.empty?

      t("lecture_home.leave.consequences.campaigns",
        campaigns: @leave.campaigns_to_withdraw.map(&:student_facing_title).to_sentence)
    end

    def admission_consequence
      t("lecture_home.leave.consequences.admission") if @leave.admitted?
    end

    def points_consequence
      return unless @lecture.assignments.exists?

      t("lecture_home.leave.consequences.points")
    end

    def dashboard_consequence
      key = @lecture.restricted? ? "dashboard_restricted" : "dashboard"
      t("lecture_home.leave.consequences.#{key}")
    end
end
