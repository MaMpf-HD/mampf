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

    def campaign_actions_id(campaign)
      "campaign_actions_#{campaign.id}"
    end

    def campaign_policy_form_frame_id(campaign)
      "policy_form_#{campaign.id}"
    end

    def campaign_policies_list_frame_id(campaign)
      "policies_list_#{campaign.id}"
    end

    def policy_kinds_summary(campaign)
      kinds = campaign.registration_policies.order(:position).map do |p|
        t("registration.policy.kinds.#{p.kind}")
      end
      kinds.join(", ")
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

    def no_campaign_registerables(lecture)
      active_campaign_ids = lecture.registration_campaigns
                                   .where.not(status: :completed)
                                   .select(:id)

      tutorial_ids_in_active = Registration::Item
                               .where(registration_campaign_id: active_campaign_ids)
                               .where(registerable_type: "Tutorial")
                               .select(:registerable_id)

      cohort_ids_in_active = Registration::Item
                             .where(registration_campaign_id: active_campaign_ids)
                             .where(registerable_type: "Cohort")
                             .select(:registerable_id)

      talk_ids_in_active = Registration::Item
                           .where(registration_campaign_id: active_campaign_ids)
                           .where(registerable_type: "Talk")
                           .select(:registerable_id)

      tutorials = lecture.tutorials.includes(:tutors).where(
        "skip_campaigns = ? OR tutorials.id NOT IN (?)",
        true,
        tutorial_ids_in_active
      )

      talks = lecture.talks.includes(:speakers).where(
        "skip_campaigns = ? OR talks.id NOT IN (?)",
        true,
        talk_ids_in_active
      )

      cohorts = lecture.cohorts
                       .where.not(id: cohort_ids_in_active)

      (tutorials.to_a + cohorts.to_a + talks.to_a)
        .sort_by { |r| r.title.to_s.downcase }
    end

    def finalize_campaign_button(campaign, size: nil, disabled: false)
      classes = ["btn", "btn-danger", size].compact.join(" ")

      button_to(t("registration.campaign.actions.finalize"),
                finalize_registration_campaign_allocation_path(campaign),
                method: :patch,
                form: {
                  data: {
                    controller: "campaign-dissolve",
                    "campaign-dissolve-confirm-message-value":
                      t("registration.campaign.confirmations.finalize"),
                    "campaign-dissolve-warning-message-value":
                      t("registration.campaign.warnings.unlimited_items"),
                    "campaign-dissolve-campaign-id-value": campaign.id,
                    action: "submit->campaign-dissolve#submit",
                    turbo_stream: true
                  }
                },
                class: classes,
                disabled: disabled)
    end

    def allocate_campaign_button(campaign, size: nil)
      has_allocation = campaign.last_allocation_calculated_at.present?
      label = if has_allocation
        t("registration.campaign.actions.reallocate")
      else
        t("registration.campaign.actions.allocate")
      end
      confirm = has_allocation ? t("registration.campaign.confirmations.reallocate") : nil
      classes = ["btn", "btn-primary", size].compact.join(" ")

      button_to(label,
                registration_campaign_allocation_path(campaign),
                method: :post,
                class: classes,
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
