module Registration
  module UserRegistrationsHelper
    def registration_status_color(registration)
      {
        pending: "secondary",
        confirmed: "success",
        rejected: "danger"
      }[registration.status.to_sym]
    end
  end
end
