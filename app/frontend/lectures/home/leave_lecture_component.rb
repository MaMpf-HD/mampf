class LeaveLectureComponent < ViewComponent::Base
  ID = "leave-lecture-dialog".freeze

  def initialize(lecture:, leave:)
    super()
    @lecture = lecture
    @leave = leave
  end

  def render?
    @leave.participating?
  end

  delegate :blockers, to: :@leave

  def confirmation_word
    t("lecture_home.leave.confirmation_word")
  end

  def contact?
    blockers.any?(&:staff_can_help)
  end

  def consequences
    [groups_consequence, campaigns_consequence, results_consequence, dashboard_consequence,
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

    def results_consequence
      points = @lecture.assignments.exists?
      admitted = @leave.admitted?
      return unless points || admitted

      key = if points && admitted
        "points_and_admission"
      else
        points ? "points" : "admission"
      end
      t("lecture_home.leave.consequences.#{key}")
    end

    def dashboard_consequence
      key = @lecture.restricted? ? "dashboard_restricted" : "dashboard"
      t("lecture_home.leave.consequences.#{key}")
    end
end
