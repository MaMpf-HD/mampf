# Lists who is in a tutorial or a cohort for its tutors, and, while its
# registration runs and the roster is still to be filled, who has registered
# for it so far.
class TutorialParticipantsComponent < ViewComponent::Base
  def initialize(group:)
    super()
    @group = group
  end

  attr_reader :group

  def members
    @members ||= group.members.includes(User::PROGRAM_PRELOAD).by_last_name.to_a
  end

  # The item of the group's running registration, if there is one; a group is
  # an item of one campaign at most.
  def running_item
    return @running_item if defined?(@running_item)

    @running_item = group.registration_items.running
                         .includes(:registration_campaign).first
  end

  def campaign
    running_item&.registration_campaign
  end

  def registered
    return @registered if defined?(@registered)

    users = running_item&.provisional_users
    @registered = users&.includes(User::PROGRAM_PRELOAD)&.by_last_name.to_a
  end

  def allocation_pending?
    running_item.present? && running_item.provisional_users.nil?
  end

  # "8 × B.Sc. Mathematik · 3 × …", most frequent first: the mix of a group at a
  # glance, before the rows.
  def program_summary(users)
    counts = users.map { |user| user.program&.name_with_subject }.tally
    parts = counts.sort_by { |name, count| [-count, name.to_s] }.map do |name, count|
      "#{count} × #{name || t("tutorial.participants.no_program")}"
    end
    parts.join(" · ")
  end

  def campaign_title
    campaign.description.to_s.strip.presence || campaign.student_facing_title
  end
end
