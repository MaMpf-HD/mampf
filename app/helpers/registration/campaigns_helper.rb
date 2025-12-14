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

    def item_stats_label(campaign)
      if campaign.first_come_first_served? || campaign.processing? || campaign.completed?
        t("registration.item.columns.registrations")
      else
        t("registration.item.columns.first_choice")
      end
    end

    def item_stats_count(item)
      campaign = item.registration_campaign
      if campaign.first_come_first_served? || campaign.processing? || campaign.completed?
        item.confirmed_registrations_count
      else
        item.user_registrations.where(preference_rank: 1).count
      end
    end
  end
end
