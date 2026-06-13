module Registration
  module ItemsHelper
    def item_display_type(item)
      case item.registerable_type
      when "Tutorial"
        t("registration.item.types.tutorial")
      when "Talk"
        "#{t("registration.item.types.talk")} #{item.registerable.position}"
      when "Cohort"
        t("registration.item.types.other_group")
      end
    end
  end
end
