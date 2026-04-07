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

    def campaign_open_confirmation(campaign)
      msg = t("registration.campaign.confirmations.open")
      if campaign.registration_items.any? { |i| i.capacity.nil? }
        msg += "\n\n#{t("registration.campaign.warnings.unlimited_items")}"
      end
      msg
    end
  end
end
