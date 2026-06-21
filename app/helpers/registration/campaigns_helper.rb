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

    def finalize_campaign_button(campaign, size: nil, disabled: false)
      classes = ["btn", "allocation-action-primary", size].compact.join(" ")

      button_to(t("registration.campaign.actions.finalize"),
                finalize_registration_campaign_allocation_path(campaign),
                method: :patch,
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

    def allocate_campaign_button(campaign, size: nil)
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
                class: classes,
                form: { data: form_data })
    end

    def closed_early?(campaign)
      !campaign.open_for_registrations? && campaign.registration_deadline > Time.current
    end

    private

      def unassigned_summary_item_css_class(item)
        [item[:count].positive? ? "text-danger" : "text-muted", "fw-medium"].join(" ")
      end
  end
end
