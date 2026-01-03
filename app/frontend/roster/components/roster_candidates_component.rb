# Renders a list of unassigned candidates for a given group type.
# Candidates are users who have registered in a campaign but are not assigned to any group.
class RosterCandidatesComponent < ViewComponent::Base
  include RosterTransferable

  def initialize(lecture:, group_type:)
    super()
    @lecture = lecture
    @group_type = group_type
  end

  def render?
    registerable_class_name.present?
  end

  def candidates
    @candidates ||= fetch_candidates
  end

  def fresh_candidates
    candidates.reject { |u| previously_assigned?(u) }
  end

  def previously_assigned_candidates
    candidates.select { |u| previously_assigned?(u) }
  end

  def available_groups
    return [] unless render?

    # Memoize to avoid re-fetching for every student row in the view if accessed multiple times
    @available_groups ||= @lecture.public_send(primary_group_type).order(:title).reject(&:locked?)
  end

  def previously_assigned?(user)
    # Check if any registration for this user in the relevant campaigns has been materialized.
    relevant_registrations(user).any? { |r| r.materialized_at.present? }
  end

  def add_member_path(group, user)
    case group
    when Tutorial
      helpers.add_member_tutorial_path(group, user_id: user.id, tab: "enrollment",
                                              group_type: @group_type)
    when Talk
      helpers.add_member_talk_path(group, user_id: user.id, tab: "enrollment",
                                          group_type: @group_type)
    end
  end

  def candidate_info(user)
    # Group by campaign to show source
    relevant_registrations(user).group_by(&:registration_campaign)
                                .map do |campaign, campaign_regs|
      {
        campaign_title: campaign.description.presence || "Campaign ##{campaign.id}",
        wishes: format_wishes(campaign_regs)
      }
    end
  end

  private

    def primary_group_type
      types = Array(@group_type)
      return :tutorials if types.include?(:tutorials)

      :talks if types.include?(:talks)
    end

    def registerable_class_name
      @registerable_class_name ||= case primary_group_type
                                   when :tutorials then "Tutorial"
                                   when :talks then "Talk"
      end
    end

    def relevant_registrations(user)
      # Filter in memory because we eager loaded them in fetch_candidates
      user.user_registrations.select do |r|
        r.registration_campaign.campaignable_id == @lecture.id &&
          r.registration_item&.registerable_type == registerable_class_name
      end
    end

    def fetch_candidates
      return [] unless render?

      # Find all campaigns for this lecture that handle this item type
      campaigns = Registration::Campaign.where(campaignable: @lecture, status: :completed,
                                               planning_only: false)
                                        .joins(:registration_items)
                                        .where(registration_items:
                                        { registerable_type: registerable_class_name })
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

    def format_wishes(registrations)
      # Sort by preference rank (if present)
      sorted = registrations.sort_by { |r| r.preference_rank || 999 }

      sorted.map do |r|
        r.registration_item.registerable.title
      end.join(", ")
    end
end
