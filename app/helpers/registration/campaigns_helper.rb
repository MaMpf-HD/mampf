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
        item.first_choice_count
      end
    end

    def item_capacity_percentage(item)
      return 0 if item.capacity.to_i.zero?

      (item.confirmed_registrations_count.to_f / item.capacity * 100).clamp(0, 100)
    end

    def item_capacity_progress_color(item)
      percentage = item_capacity_percentage(item)

      if percentage >= 100
        "danger"
      elsif percentage >= 80
        "warning"
      else
        "success"
      end
    end

    def show_item_capacity_progress?(item)
      item.registration_campaign.first_come_first_served? && item.capacity.to_i.positive?
    end

    def campaign_close_confirmation(campaign)
      key = campaign.registration_deadline > Time.current ? "close_early" : "close"
      t("registration.campaign.confirmations.#{key}")
    end
  end
end
