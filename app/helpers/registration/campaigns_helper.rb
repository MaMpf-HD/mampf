module Registration
  module CampaignsHelper
    SUMMARY_ITEM_TRANSLATION_KEYS = {
      total_registrations: "registration.allocation.stats.total_registrations",
      currently_confirmed: "registration.allocation.stats.currently_confirmed_inline",
      currently_rejected: "registration.allocation.stats.currently_rejected_inline",
      eligible: "registration.allocation.stats.eligible_inline",
      assigned: "registration.allocation.stats.assigned_inline",
      rejected: "registration.allocation.stats.rejected_inline",
      unassigned: "registration.allocation.stats.unassigned_inline"
    }.freeze

    SUMMARY_ITEM_CSS_CLASSES = {
      total_registrations: "fw-medium",
      currently_confirmed: "text-success fw-medium",
      currently_rejected: "text-danger fw-medium",
      eligible: "fw-medium",
      assigned: "text-success fw-medium",
      rejected: "text-danger fw-medium"
    }.freeze

    def email_domain(email)
      email.to_s.split("@").last
    end

    def allocation_summary_item_translation_key(item)
      SUMMARY_ITEM_TRANSLATION_KEYS.fetch(item.fetch(:kind))
    end

    def allocation_summary_item_css_class(item)
      return unassigned_summary_item_css_class(item) if item[:kind] == :unassigned

      SUMMARY_ITEM_CSS_CLASSES.fetch(item.fetch(:kind))
    end

    def campaign_badge_color(campaign)
      {
        draft: "secondary",
        open: "success",
        closed: "warning",
        processing: "info",
        completed: "dark"
      }[campaign.status.to_sym]
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

    def policy_kinds_summary(campaign)
      kinds = campaign.registration_policies.order(:position).map do |p|
        t("registration.policy.kinds.#{p.kind}")
      end
      kinds.join(", ")
    end

    def sorted_preference_counts(stats)
      stats.preference_counts.sort_by { |k, _| k == :forced ? 999 : k }
    end

    def allocation_progress_bar(value, max, bar_class:, height: "10px",
                                show_label: false)
      percentage = clamped_percentage(value, max)
      clamped_value = clamped_progress_value(value, max)

      tag.div(class: "progress", style: "height: #{height}") do
        tag.div(class: ["progress-bar", "allocation-progress-bar", bar_class].join(" "),
                role: "progressbar",
                style: "width: #{percentage}%",
                "aria-valuenow": clamped_value,
                "aria-valuemin": 0,
                "aria-valuemax": max) do
          "#{percentage.round}%" if show_label
        end
      end
    end

    def allocation_rank_bar_class(rank)
      case rank
      when :forced then "allocation-progress-bar--forced"
      when 1 then "allocation-progress-bar--first"
      when 2 then "allocation-progress-bar--second"
      else "allocation-progress-bar--other"
      end
    end

    def allocation_utilization_bar_class(percentage)
      if percentage >= 100
        "allocation-progress-bar--utilization-high"
      elsif percentage >= 80
        "allocation-progress-bar--utilization-mid"
      else
        "allocation-progress-bar--utilization-low"
      end
    end

    def rank_label(rank)
      if rank == :forced
        t("registration.allocation.stats.forced")
      else
        t("registration.allocation.stats.rank_label", rank: rank)
      end
    end

    def campaign_close_confirmation(campaign)
      key = campaign.registration_deadline > Time.current ? "close_early" : "close"
      t("registration.campaign.confirmations.#{key}")
    end

    def campaign_open_confirmation(campaign)
      msg = t("registration.campaign.confirmations.open")
      if campaign.registration_items.any? { |i| i.capacity.nil? }
        msg += "\n\n#{t("registration.campaign.warnings.unlimited_items")}"
      end
      msg
    end

    def campaign_finalize_confirmation
      t("registration.campaign.confirmations.finalize")
    end

    def finalize_campaign_button(campaign, size: nil, disabled: false, params: {})
      classes = ["btn", "allocation-action-primary", size].compact.join(" ")

      button_to(t("registration.campaign.actions.finalize"),
                finalize_registration_campaign_allocation_path(campaign),
                method: :patch,
                params: params,
                form: {
                  data: {
                    controller: "campaign-dissolve",
                    "campaign-dissolve-confirm-message-value": campaign_finalize_confirmation,
                    action: "submit->campaign-dissolve#submit",
                    turbo_stream: true
                  }
                },
                class: classes,
                disabled: disabled)
    end

    def allocate_campaign_button(campaign, size: nil, params: {})
      has_allocation = campaign.last_allocation_calculated_at.present?
      label = if has_allocation
        t("registration.campaign.actions.reallocate")
      else
        t("registration.campaign.actions.allocate")
      end
      confirm = has_allocation ? t("registration.campaign.confirmations.reallocate") : nil
      classes = ["btn", "btn-outline-primary", size].compact.join(" ")

      form_data = { turbo_stream: true }
      form_data[:turbo_confirm] = confirm if confirm

      button_to(label,
                registration_campaign_allocation_path(campaign),
                method: :post,
                params: params,
                class: classes,
                form: { data: form_data })
    end

    def view_allocation_button(campaign, params: {})
      link_to(t("registration.campaign.actions.view_allocation"),
              registration_campaign_allocation_path(campaign, **params),
              class: "btn btn-secondary",
              data: { turbo_stream: true })
    end

    def review_and_finalize_button(campaign, params: {})
      link_to(t("registration.campaign.actions.review_and_finalize"),
              registration_campaign_allocation_path(campaign, **params),
              class: "btn allocation-action-accent",
              data: { turbo_stream: true })
    end

    def open_campaign_button(campaign, params: {})
      button_to(t("registration.campaign.actions.open"),
                open_registration_campaign_path(campaign),
                method: :patch,
                params: params,
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

    def close_campaign_button(campaign, params: {})
      button_to(t("registration.campaign.actions.close"),
                close_registration_campaign_path(campaign),
                method: :patch,
                params: params,
                data: { confirm: campaign_close_confirmation(campaign),
                        turbo_stream: true },
                class: "btn btn-warning")
    end

    def reopen_campaign_button(campaign, params: {})
      button_to(t("registration.campaign.actions.reopen"),
                reopen_registration_campaign_path(campaign),
                method: :patch,
                params: params,
                data: { confirm: t("registration.campaign.confirmations.reopen"),
                        turbo_stream: true },
                class: "btn allocation-action-secondary")
    end

    def closed_early?(campaign)
      !campaign.open_for_registrations? && campaign.registration_deadline > Time.current
    end

    # Options for the post-finalization "open for self-service" select.
    # Phrased as permissions ("Allow …"), with the group's current mode
    # flagged so the teacher sees what is in effect right now.
    def self_service_mode_options(current_mode = nil)
      Rosters::Rosterable::SELF_MATERIALIZATION_MODES.keys.map do |mode|
        label = t("registration.campaign.self_service.modes.#{mode}")
        if mode.to_s == current_mode.to_s
          label += " #{t("registration.campaign.self_service.current_state_suffix")}"
        end
        [label, mode.to_s]
      end
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

      def unassigned_summary_item_css_class(item)
        [item[:count].positive? ? "text-danger" : "text-muted", "fw-medium"].join(" ")
      end
  end
end
