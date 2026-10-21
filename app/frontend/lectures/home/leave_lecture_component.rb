# The last block of a student's lecture home: ends the participation in the
# lecture, or says why the student cannot do that alone. Folded, since it is
# rarely needed and should not be pressed by accident.
class LeaveLectureComponent < ViewComponent::Base
  def initialize(lecture:, user:)
    super()
    @lecture = lecture
    @leave = Rosters::LectureLeave.new(lecture, user)
  end

  def render?
    @leave.participating?
  end

  delegate :blockers, to: :@leave

  def contact?
    blockers.any?(&:contact)
  end

  # What leaving does for this student, one sentence each.
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
      return if @leave.withdrawn_campaigns.empty?

      t("lecture_home.leave.consequences.campaigns",
        campaigns: @leave.withdrawn_campaigns.map(&:student_facing_title).to_sentence)
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
