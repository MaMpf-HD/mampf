# Shows tutorial and flexible-group counts for the dean's office's tutorial
# planning. Leaves out exams and talks, which do not bear on the tutorials it
# pays for. Counts the students by subject too: other faculties pay for the
# students of their own subjects.
class DeansOfficeDetailsComponent < ViewComponent::Base
  Section = Struct.new(:phase, :campaign, :groups)

  delegate :group_count, to: :@overview

  def initialize(overview:, course:)
    super()
    @overview = overview
    @course = course
  end

  def sections
    @sections ||= begin
      groups = @course.tutorials.sort_by(&:title) + @course.cohorts.sort_by(&:title)
      groups.group_by { |group| [@overview.group_phase(group), @overview.campaign(group)] }
            .map { |(phase, campaign), members| Section.new(phase, campaign, members) }
            .sort_by { |section| DeansOffice::TermOverview::LINE_ORDER.index(section.phase) }
    end
  end

  def groups
    @groups ||= sections.flat_map(&:groups)
  end

  def programs
    @programs ||= @overview.program_distribution(@course)
  end

  # Names the phase, and for a registration its deadline and mode, which say
  # how settled the figures are.
  def heading(section)
    phase = t("deans_office.phases.#{section.phase}")
    return phase unless section.campaign

    deadline = l(section.campaign.registration_deadline, format: :short)
    phase = t("deans_office.details.open_until", deadline: deadline) if section.phase == :open
    parts = [phase, mode(section)]
    unless section.phase == :open
      key = section.phase == :allocating ? "deadline_passed" : "deadline"
      parts << t("deans_office.details.#{key}", deadline: deadline)
    end
    parts.join(" · ")
  end

  def help(section)
    texts = [t("deans_office.help.phases.#{section.phase}")]
    texts << t("deans_office.help.modes.#{mode_key(section.campaign)}") if section.campaign
    texts.join(" ")
  end

  def bar_title(section)
    return t("deans_office.details.bar.entered") unless provisional?(section)

    key = preference?(section.campaign) ? "first_choices" : "provisional"
    t("deans_office.details.bar.#{key}")
  end

  def provisional?(section)
    section.phase.in?([:open, :allocating])
  end

  # The bars compare the groups with each other, since the limits teachers set
  # say nothing about the quotas the dean's office pays by.
  def largest_group
    @largest_group ||= [groups.map { |group| group_count(group) }.max.to_i, 1].max
  end

  def located?
    return @located if defined?(@located)

    @located = groups.any? { |group| group.try(:location).present? }
  end

  private

    def preference?(campaign)
      campaign && !campaign.first_come_first_served?
    end

    def mode_key(campaign)
      campaign.first_come_first_served? ? "first_come" : "preferences"
    end

    # Calls the figures first choices only while they are: a prepared
    # preference registration still shows the people in the group.
    def mode(section)
      return t("deans_office.modes.first_come") unless preference?(section.campaign)
      return t("deans_office.modes.preferences") unless provisional?(section)

      t("deans_office.details.first_choices", mode: t("deans_office.modes.preferences"))
    end
end
