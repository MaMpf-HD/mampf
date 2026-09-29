# Lists who is in a tutorial for its tutors, and, while its registration runs
# and the roster is still to be filled, who has registered for it so far.
class TutorialParticipantsComponent < ViewComponent::Base
  def initialize(tutorial:)
    super()
    @tutorial = tutorial
  end

  attr_reader :tutorial

  def members
    @members ||= tutorial.members.includes(User::PROGRAM_PRELOAD).by_last_name.to_a
  end

  # The item of the tutorial's running registration, if there is one; a
  # tutorial is an item of one campaign at most.
  def running_item
    return @running_item if defined?(@running_item)

    @running_item = tutorial.registration_items.running
                            .includes(:registration_campaign).first
  end

  def campaign
    running_item&.registration_campaign
  end

  # Nil while a preference campaign has not allocated yet.
  def registered
    return @registered if defined?(@registered)

    users = running_item&.provisional_users
    @registered = users&.includes(User::PROGRAM_PRELOAD)&.by_last_name.to_a
  end

  def allocation_pending?
    running_item.present? && running_item.provisional_users.nil?
  end

  def campaign_title
    campaign.description.to_s.strip.presence || campaign.student_facing_title
  end
end
