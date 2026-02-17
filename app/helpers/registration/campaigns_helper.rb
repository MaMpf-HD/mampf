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

    def campaign_accordion_item_id(campaign)
      "campaign_accordion_item_#{campaign.id}"
    end

    def campaign_accordion_collapse_id(campaign)
      "campaign_accordion_collapse_#{campaign.id}"
    end

    def campaign_header_frame_id(campaign)
      "campaign_header_frame_#{campaign.id}"
    end

    def campaign_items_tab_id(campaign)
      "campaign_#{campaign.id}_items"
    end

    def campaign_policies_tab_id(campaign)
      "campaign_#{campaign.id}_policies"
    end

    def campaign_registrations_tab_id(campaign)
      "campaign_#{campaign.id}_registrations"
    end

    def campaign_policy_form_frame_id(campaign)
      "policy_form_#{campaign.id}"
    end

    def campaign_policies_list_frame_id(campaign)
      "policies_list_#{campaign.id}"
    end

    def campaign_registrations_tab_count_id(campaign)
      "registrations_tab_count_#{campaign.id}"
    end

    def campaign_user_registrations_list_id(campaign)
      "user_registrations_list_#{campaign.id}"
    end

    def item_stats_label(campaign)
      if campaign.first_come_first_served? || campaign.processing? || campaign.completed?
        t("registration.item.columns.registrations")
      else
        t("registration.item.columns.first_choice")
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
                data: { confirm: confirm, turbo_stream: true })
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
      button_to(t("registration.campaign.actions.open"),
                open_registration_campaign_path(campaign),
                method: :patch,
                form: {
                  data: {
                    controller: "campaign-action",
                    "campaign-action-campaign-id-value": campaign.id,
                    "campaign-action-confirm-message-value":
                      t("registration.campaign.confirmations.open"),
                    "campaign-action-warning-message-value":
                      t("registration.campaign.warnings.unlimited_items"),
                    action: "submit->campaign-action#confirm",
                    turbo_stream: true
                  }
                },
                class: "btn btn-success")
    end

    def close_campaign_button(campaign)
      button_to(t("registration.campaign.actions.close"),
                close_registration_campaign_path(campaign),
                method: :patch,
                data: { confirm: campaign_close_confirmation(campaign),
                        turbo_stream: true },
                class: "btn btn-warning")
    end

    def reopen_campaign_button(campaign)
      button_to(t("registration.campaign.actions.reopen"),
                reopen_registration_campaign_path(campaign),
                method: :patch,
                data: { confirm: t("registration.campaign.confirmations.reopen"),
                        turbo_stream: true },
                class: "btn btn-success")
    end

    def closed_early?(campaign)
      !campaign.open_for_registrations? && campaign.registration_deadline > Time.current
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
