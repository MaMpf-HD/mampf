# Icon and label for a Registration::StatusQuery status, shared by the
# dashboard card and the lecture search result, so the two look the same.
module RegistrationStatusHelper
  REGISTRATION_STATUS_ICONS = {
    confirmed: "bi-check-circle-fill text-success",
    pending: "bi-hourglass-split text-warning",
    rejected: "bi-x-circle text-danger",
    open: "bi-person-plus text-primary"
  }.freeze

  def registration_status_icon(status)
    REGISTRATION_STATUS_ICONS[status]
  end

  def registration_status_label(status)
    return t("main.start.registration_open") if status == :open

    t("registration.user_registration.status.#{status}")
  end
end
