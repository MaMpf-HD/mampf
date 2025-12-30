# Renders a list of unassigned candidates for a given group type.
# Candidates are users who have registered in a campaign but are not assigned to any group.
class RosterCandidatesComponent < ViewComponent::Base
  def initialize(lecture:, group_type:)
    super()
    @lecture = lecture
    @group_type = group_type
  end

  def render?
    [:tutorials, :talks].include?(@group_type)
  end

  def candidates
    @candidates ||= fetch_candidates
  end

  def available_groups
    case @group_type
    when :tutorials then @lecture.tutorials.order(:title)
    when :talks then @lecture.talks.order(:title)
    else []
    end
  end

  private

    def fetch_candidates
      klass_name = case @group_type
                   when :tutorials then "Tutorial"
                   when :talks then "Talk"
                   else return []
      end

      # Find all campaigns for this lecture that handle this item type
      campaigns = Registration::Campaign.where(campaignable: @lecture, status: :completed,
                                               planning_only: false)
                                        .joins(:registration_items)
                                        .where(registration_items:
                                        { registerable_type: klass_name })
                                        .distinct

      # Aggregate unassigned users from all relevant campaigns.
      # The campaign model handles the logic of checking global allocations
      # to ensure we don't list students who are already assigned (e.g. via another campaign).
      candidate_ids = campaigns.flat_map { |c| c.unassigned_users.pluck(:id) }.uniq

      # Preload registrations to display preferences and source campaign
      User.where(id: candidate_ids)
          .includes(user_registrations: [:registration_campaign,
                                         { registration_item: :registerable }])
          .order(:name, :email)
    end

    def candidate_info(user)
      # Find relevant registrations for this user in the lecture's campaigns
      # We filter in memory because we already eager loaded them
      regs = user.user_registrations.select do |r|
        r.registration_campaign.campaignable == @lecture &&
          r.registration_item&.registerable_type ==
            (@group_type == :tutorials ? "Tutorial" : "Talk")
      end

      # Group by campaign to show source
      regs.group_by(&:registration_campaign).map do |campaign, campaign_regs|
        {
          campaign_title: campaign.description.presence || "Campaign ##{campaign.id}",
          wishes: format_wishes(campaign_regs)
        }
      end
    end

    def format_wishes(registrations)
      # Sort by preference rank (if present)
      sorted = registrations.sort_by { |r| r.preference_rank || 999 }

      sorted.map do |r|
        r.registration_item.registerable.title
      end.join(", ")
    end
end
