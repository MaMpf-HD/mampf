module Registration
  module UserRegistrationsHelper
    def registration_status_color(registration)
      {
        pending: "secondary",
        confirmed: "success",
        rejected: "danger"
      }[registration.status.to_sym]
    end

    def sort_registrations_by_rank(registrations)
      ranked, unranked = registrations.partition(&:preference_rank)
      ranked.sort_by(&:preference_rank) + unranked
    end
  end
end
