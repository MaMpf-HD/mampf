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

    # rubocop :disable Metrics/ParameterLists
    def registration_progress_bar(value, max, classification: :neutral, label: nil,
                                  height: "1.5rem", show_label: true,
                                  container_class: "progress mb-2", style: nil)
      # rubocop :enable Metrics/ParameterLists
      percentage = max.to_i.positive? ? (value.to_f / max * 100).clamp(0, 100) : 0

      color_class = case classification
                    when :utilization
                      utilization_color(percentage)
                    when :time
                      "bg-info"
                    when :neutral
                      "bg-primary"
                    else
                      "bg-#{classification}"
      end

      tag.div(class: container_class, style: [style, "height: #{height}"].compact.join("; ")) do
        tag.div(class: "progress-bar #{color_class}",
                role: "progressbar",
                style: "width: #{percentage}%",
                "aria-valuenow": value,
                "aria-valuemin": 0,
                "aria-valuemax": max) do
          label || "#{percentage.round}%" if show_label
        end
      end
    end

    def sorted_preference_counts(stats)
      stats.preference_counts.sort_by { |k, _| k == :forced ? 999 : k }
    end

    def rank_color(rank)
      case rank
      when :forced then :danger
      when 1 then :success
      when 2 then :primary
      else :secondary
      end
    end

    def rank_label(rank)
      if rank == :forced
        t("registration.allocation.stats.forced")
      else
        t("registration.allocation.stats.rank_label", rank: rank)
      end
    end

    def utilization_bar_class(percentage)
      if percentage >= 100
        "bg-danger"
      elsif percentage >= 80
        "bg-warning"
      else
        "bg-success"
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

    def show_item_capacity_progress?(item)
      campaign = item.registration_campaign
      return false unless item.capacity.to_i.positive?

      campaign.first_come_first_served? || campaign.completed?
    end

    def campaign_close_confirmation(campaign)
      key = campaign.registration_deadline > Time.current ? "close_early" : "close"
      t("registration.campaign.confirmations.#{key}")
    end

    def planning_only_disabled_reason(campaign)
      return if campaign.can_be_planning_only?

      t("registration.campaign.planning_only_disabled")
    end

    def finalize_campaign_button(campaign)
      button_to(t("registration.campaign.actions.finalize"),
                finalize_registration_campaign_allocation_path(campaign),
                method: :patch,
                data: { confirm: t("registration.campaign.confirmations.finalize") },
                class: "btn btn-danger")
    end

    def allocate_campaign_button(campaign)
      has_allocation = campaign.last_allocation_calculated_at.present?
      label = if has_allocation
        t("registration.campaign.actions.reallocate")
      else
        t("registration.campaign.actions.allocate")
      end
      confirm = has_allocation ? t("registration.campaign.confirmations.reallocate") : nil

      button_to(label,
                registration_campaign_allocation_path(campaign),
                method: :post,
                class: "btn btn-primary",
                data: { confirm: confirm, turbo: true })
    end

    def view_allocation_button(campaign)
      link_to(t("registration.campaign.actions.view_allocation"),
              registration_campaign_allocation_path(campaign),
              class: "btn btn-secondary",
              data: { turbo_stream: true })
    end

    def review_and_finalize_button(campaign)
      link_to(t("registration.campaign.actions.review_and_finalize"),
              registration_campaign_allocation_path(campaign),
              class: "btn btn-primary",
              data: { turbo_stream: true })
    end

    def open_campaign_button(campaign)
      confirm_msg = t("registration.campaign.confirmations.open")
      if campaign.registration_items.any? { |i| i.capacity.nil? }
        confirm_msg += "\n\n#{t("registration.campaign.warnings.unlimited_items")}"
      end

      button_to(t("registration.campaign.actions.open"),
                open_registration_campaign_path(campaign),
                method: :patch,
                data: { confirm: confirm_msg },
                class: "btn btn-success")
    end

    def close_campaign_button(campaign)
      button_to(t("registration.campaign.actions.close"),
                close_registration_campaign_path(campaign),
                method: :patch,
                data: { confirm: campaign_close_confirmation(campaign) },
                class: "btn btn-warning")
    end

    def reopen_campaign_button(campaign)
      button_to(t("registration.campaign.actions.reopen"),
                reopen_registration_campaign_path(campaign),
                method: :patch,
                data: { confirm: t("registration.campaign.confirmations.reopen") },
                class: "btn btn-success")
    end

    def planning_only_checkbox_disabled?(campaign)
      !campaign.can_be_planning_only? || campaign.completed?
    end

    private

      def utilization_color(percentage)
        if percentage >= 100
          "bg-danger"
        elsif percentage >= 80
          "bg-warning"
        else
          "bg-success"
        end
      end
  end
end
