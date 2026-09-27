# The groups of a lecture a student joins or leaves by themselves, without a
# registration campaign and its deadline. Shown as one collapsed row among the
# campaigns; `part` renders only the summary or the body for a Turbo Stream.
class SelfEnrollmentComponent < ViewComponent::Base
  ID = "self_enrollment".freeze
  BLOCK_ID = "self_enrollment_block".freeze
  SUMMARY_ID = "self_enrollment_summary".freeze
  BODY_ID = "self_enrollment_body".freeze

  def initialize(lecture:, user:, rosterables:, part: nil)
    super()
    @lecture = lecture
    @user = user
    @rosterables = rosterables
    @part = part
  end

  attr_reader :lecture, :user, :rosterables, :part

  def render?
    rosterables.any?
  end

  def blocked?(rosterable)
    helpers.registration_blocked_by_unremovable_assignment?(lecture) &&
      rosterable.roster_exclusive_within_lecture? &&
      !rosterable.user_allocated?(user)
  end

  def switch_from(rosterable)
    return if rosterable.user_allocated?(user) || !rosterable.config_allow_self_add? ||
              rosterable.locked?

    from = rosterable.conflicting_lecture_membership(user)
    from if from&.allow_self_remove?(user)
  end

  def path_for(action, rosterable)
    helpers.public_send("#{action}_#{rosterable.class.name.underscore}_path", rosterable.id)
  end
end
