module Registration
  module CampaignsHelper
    def email_domain(email)
      email.to_s.split("@").last
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

    def campaign_close_confirmation(campaign)
      key = campaign.registration_deadline > Time.current ? "close_early" : "close"
      t("registration.campaign.confirmations.#{key}")
    end

    def no_campaign_registerables(lecture)
      Rosters::NoCampaignRegisterablesQuery.new(lecture).call
    end

    def finalize_campaign_button(campaign, size: nil, disabled: false, params: {})
      classes = ["btn", "btn-danger", size].compact.join(" ")

      button_to(t("registration.campaign.actions.finalize"),
                finalize_registration_campaign_allocation_path(campaign),
                method: :patch,
                params: params,
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

    def allocate_campaign_button(campaign, size: nil, params: {})
      has_allocation = campaign.last_allocation_calculated_at.present?
      label = if has_allocation
        t("registration.campaign.actions.reallocate")
      else
        t("registration.campaign.actions.allocate")
      end
      confirm = has_allocation ? t("registration.campaign.confirmations.reallocate") : nil
      classes = ["btn", "btn-primary", size].compact.join(" ")

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
              class: "btn btn-primary",
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
