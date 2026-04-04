module Registration
  module ItemsHelper
    def item_display_type(item)
      case item.registerable_type
      when "Tutorial"
        t("registration.item.types.tutorial")
      when "Talk"
        t("registration.item.types.talk")
      when "Cohort"
        cohort = item.registerable
        base_type = t("registration.item.types.other_group")

        if cohort.propagate_to_lecture
          base_type
        else
          icon = tag.i(class: "bi bi-person-x ms-1",
                       style: "color: #495057;",
                       data: { bs_toggle: "tooltip",
                               bs_title: t("registration.item.hints.no_propagation") })
          safe_join([base_type, " ", icon])
        end
      end
    end
  end
end
