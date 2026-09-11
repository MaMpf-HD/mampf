module Registration
  # Icon and label for a Lecture#registration_status_for(user)/
  # Registration::StatusQuery value. Shared by the dashboard card and the
  # lecture search result card, so the two stay visually consistent.
  module StatusPresenter
    ICONS = {
      confirmed: "bi-check-circle-fill text-success",
      pending: "bi-hourglass-split text-warning",
      rejected: "bi-x-circle text-danger",
      open: "bi-person-plus text-primary"
    }.freeze

    def self.icon(status)
      ICONS[status]
    end

    def self.label(status)
      return I18n.t("main.start.registration_open") if status == :open

      I18n.t("registration.user_registration.status.#{status}")
    end
  end
end
