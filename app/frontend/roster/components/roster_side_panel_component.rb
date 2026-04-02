# Missing top-level docstring, please formulate one yourself 😁
class RosterSidePanelComponent < ViewComponent::Base
  attr_reader :registerable, :students, :campaign

  def initialize(registerable: nil, students: [], read_only: false,
                 is_unassigned: false, campaign: nil)
    super()
    @registerable = registerable
    @students = students
    @read_only = read_only
    @is_unassigned = is_unassigned
    @campaign = campaign
  end

  def read_only?
    @read_only
  end

  def unassigned?
    @is_unassigned
  end

  def panel_title
    if unassigned?
      t("roster.candidates.title")
    elsif read_only?
      t("registration.user_registration.index.title",
        default: "Registrations")
    else
      t("roster.details.participants")
    end
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
