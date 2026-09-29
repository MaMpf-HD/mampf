# Formats the seat and registration figures of the dean's office table.
module DeansOfficeHelper
  def deans_office_seats(capacity, unlimited)
    return t("deans_office.unlimited") if unlimited && capacity.zero?
    return t("deans_office.seats_and_unlimited", seats: capacity) if unlimited

    capacity
  end

  # Says how people get into a group: for a running campaign with its
  # deadline and whether places go to the first or by preferences.
  def deans_office_access(access)
    campaign = access.campaign
    case access.state
    when :open
      mode = campaign.first_come_first_served? ? "first_come" : "preferences"
      t("deans_office.access.open", deadline: l(campaign.registration_deadline, format: :short),
                                    mode: t("deans_office.access.modes.#{mode}"))
    else
      t("deans_office.access.#{access.state}")
    end
  end

  # One line per way into the lecture's groups; with several, each names the
  # kinds of group it is for.
  def deans_office_accesses(accesses)
    return deans_office_access(accesses.keys.first) if accesses.one?

    safe_join(accesses.map do |access, groups|
      kinds = groups.map { |group| DeansOffice::TermOverview.group_type(group) }.uniq
      tag.div("#{kinds.map { |kind| t("deans_office.kinds.#{kind}") }.join(", ")}: " \
              "#{deans_office_access(access)}")
    end)
  end

  # First choices are marked as such: people who ranked the group lower are
  # not counted.
  def deans_office_registrations(count, first_choices: false)
    return tag.span("–", class: "text-muted") if count.nil?
    return t("deans_office.first_choices", count: count) if first_choices

    count
  end
end
