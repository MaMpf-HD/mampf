class LeaveLectureComponent < ViewComponent::Base
  def self.dialog_id(lecture)
    "leave-lecture-dialog-#{lecture.id}"
  end

  def initialize(lecture:, leave:, from_check: false)
    super()
    @lecture = lecture
    @leave = leave
    @from_check = from_check
  end

  def render?
    @leave.participating?
  end

  delegate :blockers, :confirmation_code, to: :@leave

  def dialog_id
    self.class.dialog_id(@lecture)
  end

  # The participation check shows one dialog per lecture, each with its own
  # field.
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
      return unless @leave.admission

      t("lecture_home.leave.consequences.admission_#{@leave.admission}")
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
