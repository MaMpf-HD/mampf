module Registration
  module CampaignsHelper
    def campaign_badge_color(campaign)
      {
        draft: "secondary",
        open: "success",
        closed: "warning",
        processing: "info",
        completed: "dark"
      }[campaign.status.to_sym]
    end

    def campaign_item_type_label(campaign)
      return "—" if campaign.registration_items.empty?

      type = campaign.registration_items.first.registerable_type
      t("registration.item.types.#{type.underscore}")
    end
  end
end
