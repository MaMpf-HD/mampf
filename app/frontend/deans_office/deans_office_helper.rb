# Formats the seat and registration figures of the dean's office table.
module DeansOfficeHelper
  def deans_office_seats(capacity, unlimited)
    return t("deans_office.unlimited") if unlimited && capacity.zero?
    return t("deans_office.seats_and_unlimited", seats: capacity) if unlimited

    capacity
  end

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

  # Names the kinds of group in front of each line when a lecture's groups are
  # reached in several ways, so that the lines can be told apart.
  def deans_office_accesses(accesses)
    return deans_office_access(accesses.keys.first) if accesses.one?

    safe_join(accesses.map do |access, groups|
      kinds = groups.map { |group| DeansOffice::TermOverview.group_type(group) }.uniq
      tag.div("#{kinds.map { |kind| t("deans_office.kinds.#{kind}") }.join(", ")}: " \
              "#{deans_office_access(access)}")
    end)
  end

  # Writes the count out beside the bar: an empty bar shows no label, and the
  # bar is only a picture of the figure, hidden from screen readers.
  def deans_office_members(count, capacity)
    return count unless capacity

    over = count > capacity
    tag.div(class: "d-flex align-items-center gap-2") do
      tag.span("#{count} / #{capacity}",
               class: class_names("text-nowrap", "text-danger fw-semibold": over)) +
        tag.div(class: "flex-grow-1", "aria-hidden": true) do
          progress_bar(count, capacity, classification: over ? :danger : :neutral,
                                        show_label: false, height: "0.5rem",
                                        container_class: "progress")
        end
    end
  end

  # First choices are marked as such: people who ranked the group lower are
  # not counted.
  def deans_office_registrations(count, first_choices: false)
    return tag.span("–", class: "text-muted") if count.nil?
    return t("deans_office.first_choices", count: count) if first_choices

    count
  end
end
