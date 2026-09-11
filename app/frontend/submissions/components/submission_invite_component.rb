# Somebody has offered the reader a place on their team for this sheet. Accepting
# is a join by code, only with the code already filled in.
class SubmissionInviteComponent < ViewComponent::Base
  attr_reader :invite, :assignment

  def initialize(invite:, assignment:)
    super()
    @invite = invite
    @assignment = assignment
  end

  # Whoever handed in first is the one who sent the code on.
  def inviter_name
    invite.users.first&.tutorial_name || t("submission.hub.card.unknown_inviter")
  end

  def join_params
    { join: { code: invite.token, assignment_id: assignment.id } }
  end
end
