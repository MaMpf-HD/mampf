# Formats the seat and registration figures of the dean's office table.
module DeansOfficeHelper
  def deans_office_seats(capacity, unlimited)
    return t("deans_office.unlimited") if unlimited && capacity.zero?
    return t("deans_office.seats_and_unlimited", seats: capacity) if unlimited

    capacity
  end

  # First choices are marked as such: people who ranked the group lower are
  # not counted.
  def deans_office_registrations(count, first_choices: false)
    return tag.span("–", class: "text-muted") if count.nil?
    return t("deans_office.first_choices", count: count) if first_choices

    count
  end
end
