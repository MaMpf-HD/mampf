# Renders the side panel in the roster view, showing either unassigned candidates
# or members of a group.
class RosterSidePanelComponent < ViewComponent::Base
  attr_reader :registerable, :students, :campaign, :item

  # rubocop:disable Metrics/ParameterLists
  def initialize(registerable: nil, students: [], read_only: false,
                 is_unassigned: false, campaign: nil, item: nil,
                 allocated: false, preference_ranks: {})
    super()
    @registerable = registerable
    @students = students
    @read_only = read_only
    @is_unassigned = is_unassigned
    @campaign = campaign
    @item = item
    @allocated = allocated
    @preference_ranks = preference_ranks
  end
  # rubocop:enable Metrics/ParameterLists

  def read_only?
    @read_only
  end

  def unassigned?
    @is_unassigned
  end

  def allocated?
    @allocated
  end

  def preference_rank_for(student)
    @preference_ranks[student.id]
  end

  def rank_badge_color(rank)
    case rank
    when 1 then "bg-success"
    when 2 then "bg-primary"
    when 3 then "bg-warning text-dark"
    else "bg-secondary"
    end
  end

  def rank_badge_label(rank)
    if rank.nil?
      t("registration.allocation.stats.forced_short",
        default: "Assigned")
    else
      t("registration.allocation.stats.rank_label", rank: rank)
    end
  end

  def allocated_choice_pills
    return [] unless allocated? && @preference_ranks.any?

    counts = @preference_ranks.values.tally
    pills = []
    (1..3).each do |rank|
      next unless counts[rank]&.positive?

      pills << { count: counts[rank],
                 label: rank_badge_label(rank),
                 color: rank_badge_color(rank) }
    end
    rest = counts.select { |r, _| r.is_a?(Integer) && r > 3 }.values.sum
    if rest.positive?
      pills << { count: rest,
                 label: t("registration.item.badge.other_choices",
                          default: "Other"),
                 color: "bg-secondary" }
    end
    forced = counts[nil] || 0
    if forced.positive?
      pills << { count: forced,
                 label: rank_badge_label(nil),
                 color: "bg-secondary" }
    end
    pills
  end

  def panel_title
    if unassigned?
      t("roster.candidates.title")
    elsif allocated?
      t("registration.user_registration.index.allocated_title",
        default: "Allocated Students")
    elsif read_only? && preference_based_campaign?
      t("registration.user_registration.index.first_choice_title",
        default: "1st Choice Registrations")
    elsif read_only?
      t("registration.user_registration.index.title",
        default: "Registrations")
    else
      t("roster.details.participants")
    end
  end

  def preference_based_campaign?
    item&.registration_campaign&.preference_based?
  end

  def further_choice_summary
    return unless preference_based_campaign?

    second = item.user_registrations.where(preference_rank: 2).count
    third = item.user_registrations.where(preference_rank: 3).count
    rest = item.user_registrations.where("preference_rank > 3").count

    parts = []
    if second.positive?
      parts << ("#{second} " +
               t("registration.item.badge.second_choice",
                 default: "2nd Choice"))
    end
    if third.positive?
      parts << ("#{third} " +
               t("registration.item.badge.third_choice",
                 default: "3rd Choice"))
    end
    if rest.positive?
      parts << ("#{rest} " +
               t("registration.item.badge.other_choices",
                 default: "Other"))
    end
    parts.join(", ")
  end

  def tutors_text
    return unless registerable

    helpers.roster_tutors_text(registerable)
  end

  def add_member_path
    return unless registerable

    helpers.roster_add_member_path(registerable, source: :panel)
  end

  def move_member_path_template
    return unless registerable

    helpers.roster_move_member_path_template(registerable)
  end

  def remove_member_path(student)
    return unless registerable

    helpers.roster_remove_member_path(
      registerable, student, source: :panel
    )
  end

  def drag_controller?
    !read_only? && (draggable_unassigned? || registerable.present?)
  end

  def drag_source_type
    if draggable_unassigned?
      "unassigned"
    else
      registerable.class.name.downcase
    end
  end

  def drag_source_id
    if draggable_unassigned?
      campaign.id
    else
      registerable.id
    end
  end

  def show_add_form?
    registerable.present? && !read_only? && !unassigned?
  end

  def show_remove_button?
    !read_only? && !unassigned?
  end

  def show_campaign_wishes?(student)
    unassigned? && campaign.present? && relevant_registrations(student).any?
  end

  def campaign_wishes(student)
    relevant_registrations(student)
      .sort_by { |r| r.preference_rank || 999 }
      .map { |r| r.registration_item.registerable.title }
      .join(", ")
  end

  def student_display_name(student)
    student.name.presence ||
      student.try(:tutorial_name).presence ||
      student.email
  end

  def overbooking_warning
    t("roster.warnings.confirm_overbooking")
  end

  def empty_state_text
    if read_only?
      t("roster.details.select_group",
        default: "Select a group to inspect registrations")
    else
      t("roster.details.select_group",
        default: "Select a group to inspect and manage participants")
    end
  end

  private

    def draggable_unassigned?
      unassigned? && campaign.present?
    end

    def relevant_registrations(student)
      student.user_registrations.select do |r|
        r.registration_campaign_id == campaign.id
      end
    end
end
