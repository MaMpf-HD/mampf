# Shows a course's groups and how many people each has, by the registration
# that hands them out: its deadline and mode say how settled the figures are.
# Exams and talks stay out; they do not bear on the tutorials the dean's
# office pays for.
class DeansOfficeDetailsComponent < ViewComponent::Base
  Section = Struct.new(:phase, :campaign, :groups)

  delegate :group_count, to: :@overview

  def initialize(overview:, course:)
    super()
    @overview = overview
    @course = course
  end

  # One section per running or prepared registration and one per phase for
  # the other groups, in the order of the course's line; tutorials first
  # within each.
  def sections
    @sections ||= begin
      groups = @course.tutorials.sort_by(&:title) + @course.cohorts.sort_by(&:title)
      groups.group_by { |group| [@overview.group_phase(group), @overview.campaign(group)] }
            .map { |(phase, campaign), members| Section.new(phase, campaign, members) }
            .sort_by { |section| DeansOffice::TermOverview::LINE_ORDER.index(section.phase) }
    end
  end

  def groups
    sections.flat_map(&:groups)
  end

  def heading(section)
    phase = if section.phase == :open
      t("deans_office.details.open_until",
        deadline: l(section.campaign.registration_deadline, format: :short))
    else
      t("deans_office.phases.#{section.phase}")
    end
    return phase unless section.campaign

    t("deans_office.details.by_campaign", phase: phase, mode: mode(section.campaign))
  end

  def help(section)
    texts = [t("deans_office.help.phases.#{section.phase}")]
    texts << t("deans_office.help.modes.#{mode_key(section.campaign)}") if section.campaign
    texts.join(" ")
  end

  def bar_title(section)
    key = if section.phase.in?([:open, :allocating])
      preference?(section.campaign) ? "first_choices" : "provisional"
    else
      "entered"
    end
    t("deans_office.details.bar.#{key}")
  end

  def provisional?(section)
    section.phase.in?([:open, :allocating])
  end

  # The bars compare the groups with each other, since the limits teachers set
  # say nothing about the quotas the dean's office pays by.
  def largest_group
    groups.map { |group| group_count(group) }.max.to_i
  end

  def located?
    groups.any? { |group| group.try(:location).present? }
  end

  private

    def preference?(campaign)
      campaign && !campaign.first_come_first_served?
    end

    def mode_key(campaign)
      campaign.first_come_first_served? ? "first_come" : "preferences"
    end

    def mode(campaign)
      return t("deans_office.modes.first_come") unless preference?(campaign)

      t("deans_office.details.first_choices", mode: t("deans_office.modes.preferences"))
    end
end
