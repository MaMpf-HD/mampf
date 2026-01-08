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
    registerable_class_names.present?
  end

  def candidates
    @candidates ||= grouped_candidates.flat_map { |g| g[:users] }.uniq
  end

  def grouped_candidates
    @grouped_candidates ||= Array(@group_type).filter_map do |type|
      klass_name = type_to_class_name(type)
      next unless klass_name

      users = fetch_candidates_for_class(klass_name)
      next if users.empty?

      {
        type: type,
        title: klass_name.constantize.model_name.human(count: 2),
        users: users
      }
    end
  end

  def fresh_candidates(users)
    users.reject { |u| previously_assigned?(u) }
  end

  def previously_assigned_candidates(users)
    users.select { |u| previously_assigned?(u) }
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

  def previously_assigned?(user)
    # Check if any registration for this user in the relevant campaigns has been materialized.
    relevant_registrations(user).any? { |r| r.materialized_at.present? }
  end

  def add_member_path(group, user)
    case group
    when Tutorial
      helpers.add_member_tutorial_path(
        group, user_id: user.id, tab: "enrollment", active_tab: "enrollment",
               group_type: @group_type,
               frame_id: helpers.roster_maintenance_frame_id(@group_type)
      )
    when Talk
      helpers.add_member_talk_path(
        group, user_id: user.id, tab: "enrollment", active_tab: "enrollment",
               group_type: @group_type,
               frame_id: helpers.roster_maintenance_frame_id(@group_type)
      )
    when Cohort
      helpers.add_member_cohort_path(
        group, user_id: user.id, tab: "enrollment", active_tab: "enrollment",
               group_type: @group_type,
               frame_id: helpers.roster_maintenance_frame_id(@group_type)
      )
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

    def type_to_class_name(type)
      {
        tutorials: "Tutorial",
        talks: "Talk",
        cohorts: "Cohort"
      }[type]
    end

    def relevant_registrations(user)
      # Filter in memory because we eager loaded them in fetch_candidates
      user.user_registrations.select do |r|
        r.registration_campaign.campaignable_id == @lecture.id &&
          registerable_class_names.include?(r.registration_item&.registerable_type)
      end
    end

    def fetch_candidates_for_class(klass_name)
      return [] unless render?

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

      # The campaign model only checks for assignments to groups of the SAME type.
      # However, in the roster management context, moving a student to a 'Sidecar' (Cohort)
      # should be considered a resolution of their unassigned status.
      # Therefore, we filter out users who are valid members of ANY group in this lecture.
      candidate_ids -= all_assigned_user_ids

      # Preload registrations to display preferences and source campaign
      User.where(id: candidate_ids)
          .includes(user_registrations: [:registration_campaign,
                                         { registration_item: :registerable }])
          .order(:name, :email)
    end

    def all_assigned_user_ids
      @all_assigned_user_ids ||= begin
        ids = []
        ids += @lecture.tutorials.joins(:members).pluck("users.id")
        ids += @lecture.talks.joins(:members).pluck("users.id")
        ids += @lecture.cohorts.joins(:members).pluck("users.id")
        ids.uniq
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
