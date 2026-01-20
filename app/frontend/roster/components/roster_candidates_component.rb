# Renders campaign registrations for a given group type.
# Shows students who registered in campaigns but haven't been allocated.
# Assigning them will enroll them in the lecture.
class RosterCandidatesComponent < ViewComponent::Base
  include RosterTransferable

  def initialize(lecture:, group_type:)
    super()
    @lecture = lecture
    @group_type = group_type
  end

  def render?
    registerable_class_names.present?
  end

  def candidates
    @candidates ||= fetch_all_candidates
  end

  def fetch_all_candidates
    return [] unless render?

    # Get all completed campaigns for this lecture
    campaigns = Registration::Campaign.completed.where(campaignable: @lecture)

    # Get lecture roster to exclude already-enrolled students
    lecture_roster_ids = @lecture.allocated_user_ids

    # Aggregate fresh candidates from all campaigns
    # Only include users who are NOT on lecture roster (truly fresh)
    candidate_ids = campaigns.flat_map do |c|
      c.unassigned_users
       .where.not(id: lecture_roster_ids)
       .joins(:user_registrations)
       .where(user_registrations: {
                registration_campaign_id: c.id,
                materialized_at: nil
              })
       .pluck(:id)
    end.uniq

    # Preload registrations to display preferences and source campaign
    User.where(id: candidate_ids)
        .includes(user_registrations: [:registration_campaign,
                                       { registration_item: :registerable }])
        .order(:name, :email)
  end

  def available_groups
    return [] unless render?

    @available_groups ||= begin
      groups = []
      Array(@group_type).each do |type|
        next unless @lecture.respond_to?(type)

        groups.concat(@lecture.public_send(type).reject(&:locked?))
      end
      groups.sort_by(&:title)
    end
  end

  def add_member_path(group, user)
    case group
    when Tutorial
      helpers.add_member_tutorial_path(group, user_id: user.id, tab: "enrollment",
                                              group_type: @group_type)
    when Talk
      helpers.add_member_talk_path(group, user_id: user.id, tab: "enrollment",
                                          group_type: @group_type)
    when Cohort
      helpers.add_member_cohort_path(group, user_id: user.id, tab: "enrollment",
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

    def registerable_class_names
      types = Array(@group_type)
      classes = []
      classes << "Tutorial" if types.include?(:tutorials)
      classes << "Talk" if types.include?(:talks)
      classes << "Cohort" if types.include?(:cohorts)
      classes
    end

    def relevant_registrations(user)
      # Filter in memory because we eager loaded them in fetch_candidates
      user.user_registrations.select do |r|
        r.registration_campaign.campaignable_id == @lecture.id &&
          registerable_class_names.include?(r.registration_item&.registerable_type)
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
