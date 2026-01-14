module Registration
  module ItemsHelper
    def registration_items_service(campaign)
      @registration_items_service ||= Registration::AvailableItemsService.new(campaign)
    end

    def item_display_type(item)
      case item.registerable_type
      when "Tutorial"
        t("registration.item.types.tutorial")
      when "Talk"
        t("registration.item.types.talk")
      when "Cohort"
        cohort = item.registerable
        base_type = case cohort.purpose.to_sym
                    when :enrollment
                      t("registration.item.types.enrollment_group")
                    when :planning
                      t("registration.item.types.planning_survey")
                    when :general
                      t("registration.item.types.other_group")
        end

        if cohort.propagate_to_lecture
          base_type
        else
          "#{base_type} <i class='bi bi-person-x ms-1' style='color: #495057;' data-bs-toggle='tooltip' title='#{t("registration.item.hints.no_propagation")}'></i>".html_safe
        end
      end
    end

    def format_capacity(capacity)
      if capacity.nil?
        t("basics.unlimited")
      else
        "#{capacity} #{t("basics.seats")}"
      end
    end
  end
end
