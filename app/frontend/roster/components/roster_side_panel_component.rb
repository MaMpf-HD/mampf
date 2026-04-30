# Renders the side panel in the roster view, showing either unassigned candidates
# or members of a group.
class RosterSidePanelComponent < ViewComponent::Base
  attr_reader :registerable, :students, :campaign, :item

  # rubocop:disable Metrics/ParameterLists
  def initialize(registerable: nil, students: [], read_only: false,
                 panel_kind: nil, campaign: nil, item: nil,
                 allocated: false, preference_ranks: {})
    super()
    @registerable = registerable
    @students = students
    @read_only = read_only
    @panel_kind = panel_kind&.to_sym
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
    @panel_kind == :unassigned
  end

  def rejected?
    @panel_kind == :rejected
  end

  def panel_mode?
    @panel_kind.present?
  end

  def campaign_panel?
    panel_mode? && campaign.present?
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
    case @panel_kind
    when :rejected
      t("registration.user_registration.index.rejected_title",
        default: "Rejected Registrations")
    when :unassigned
      t("roster.candidates.title")
    else
      if allocated?
        return t("registration.user_registration.index.allocated_title",
                 default: "Allocated Students")
      end

      if read_only? && preference_based_campaign?
        return t("registration.user_registration.index.first_choice_title",
                 default: "1st Choice Registrations")
      end

      if read_only?
        return t("registration.user_registration.index.title",
                 default: "Registrations")
      end

      t("roster.details.participants")
    end
  end

  def preference_based_campaign?
    item&.registration_campaign&.preference_based?
  end

  def further_choice_summary
    return unless preference_based_campaign?

    counts = item.user_registrations
                 .where("preference_rank >= 2")
                 .group(:preference_rank).count

    second = counts[2] || 0
    third = counts[3] || 0
    rest = counts.select { |r, _| r > 3 }.values.sum

    parts = []
    if second.positive?
      parts << ("#{second} " +
               t("registration.item.badge.second_choice"))
    end
    if third.positive?
      parts << ("#{third} " +
               t("registration.item.badge.third_choice"))
    end
    if rest.positive?
      parts << ("#{rest} " +
               t("registration.item.badge.other_choices"))
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
    !read_only? && (campaign_panel? || (registerable.present? && !panel_mode?))
  end

  def drag_source_type
    campaign_panel? ? @panel_kind.to_s : registerable.class.name.downcase
  end

  def drag_source_id
    campaign_panel? ? campaign.id : registerable.id
  end

  def show_add_form?
    registerable.present? && !read_only? && !panel_mode?
  end

  def show_remove_button?
    registerable.present? && !read_only? && !panel_mode?
  end

  def show_campaign_wishes?(student)
    campaign_panel? && relevant_registrations(student).any?
  end

  def campaign_wishes(student)
    relevant_registrations(student)
      .sort_by { |r| r.preference_rank || 999 }
      .map { |r| r.registration_item.registerable.title }
      .join(", ")
  end

  def show_rejection_reasons?(student)
    rejected? && rejection_reasons(student).present?
  end

  def rejection_reasons(student)
    relevant_registrations(student)
      .select { |r| rejected_registration?(r) }
      .filter_map do |registration|
        Registration::UserRegistration.localized_rejection_reason_label(
          reason_code: registration.rejection_reason_code,
          reason_label: registration.rejection_reason_label
        )
      end
      .uniq
      .join(", ")
  end

  def campaign_panel_count_label
    case @panel_kind
    when :rejected
      t("roster.candidates.rejected_short", default: "rejected")
    when :unassigned
      t("roster.candidates.short_title", default: "unplaced")
    else
      t("registration.item.columns.registrations",
        default: "Registrations")
    end
  end

  def campaign_panel_description
    return unless campaign_panel? && campaign.completed?

    case @panel_kind
    when :rejected
      t("roster.candidates.rejected_description")
    when :unassigned
      t("roster.candidates.completed_description")
    end
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
    t("roster.details.select_group")
  end

  private

    def relevant_registrations(student)
      student.user_registrations.select do |r|
        r.registration_campaign_id == campaign.id
      end
    end

    def rejected_registration?(registration)
      return registration.rejected? if registration.respond_to?(:rejected?)

      registration.respond_to?(:status) && registration.status.to_s == "rejected"
    end
end
