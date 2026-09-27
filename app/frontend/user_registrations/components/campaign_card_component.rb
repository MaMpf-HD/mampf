# Renders an open campaign as a collapsed row whose options are only loaded
# when it is opened, so the page does not carry every campaign's options.
class CampaignCardComponent < ViewComponent::Base
  include EligibilityHelper

  def initialize(details:, campaign:, part: nil, focus: false)
    super()
    @details = details
    @campaign = campaign
    @part = part
    @focus = focus
  end

  attr_reader :details, :campaign, :part, :focus

  def anchor_id
    dom_id(campaign, :student_registration)
  end

  def summary_id
    dom_id(campaign, :student_registration_summary)
  end

  def body_id
    dom_id(campaign, :student_registration_body)
  end

  def lazy?
    details.summary_only
  end

  def body_url
    helpers.lecture_home_campaign_path(campaign.campaignable, campaign_id: campaign.id)
  end

  def body_element(content)
    placeholder = tag.p(t("registration.user_registration.summary.loading"),
                        class: "registration-fold-loading mb-0")
    tag.div(lazy? ? placeholder : content,
            class: "registration-fold-body", id: body_id,
            data: { registration_fold_target: "body", loaded: !lazy? })
  end

  def own_registrations
    Array(details.own_registrations)
  end

  def registered_items
    @registered_items ||= own_registrations.select(&:confirmed?).map(&:registration_item)
  end

  def saved_preferences
    @saved_preferences ||= own_registrations.select { |r| r.pending? && r.preference_rank }
                                            .sort_by(&:preference_rank)
  end

  def preferences_saved?
    saved_preferences.any?
  end

  def full?
    campaign.first_come_first_served? && registered_items.empty? &&
      items.none?(&:still_has_capacity?)
  end

  # What the student holds comes first, a registration or saved preferences;
  # a requirement that fails for them is added beside it by risk_badge.
  def summary_badge
    return [:ok, t("registration.user_registration.summary.registered")] if registered_items.any?
    return [:info, t("registration.user_registration.summary.preferences_saved")] if
      preferences_saved?
    return [:bad, t("registration.user_registration.summary.requirement_missing")] if ineligible?
    return [:bad, t("registration.user_registration.summary.blocked")] if blocked?
    return [:info, t("registration.user_registration.summary.full")] if full?

    key = campaign.preference_based? ? "no_preferences" : "not_registered"
    [:warn, t("registration.user_registration.summary.#{key}")]
  end

  def summary_lines
    [own_line || (ineligible? ? ineligible_line : mode_line), risk_line, deadline_line].compact
  end

  # A registration or preferences the student holds while a requirement fails:
  # the row says so next to the student's state, since finalization would
  # reject them.
  def at_risk?
    (registered_items.any? || preferences_saved?) &&
      (ineligible? || finalization_policy_warning?)
  end

  def risk_badge
    [:bad, t("registration.user_registration.summary.requirement_missing")] if at_risk?
  end

  def cta_label
    return t("registration.user_registration.summary.change") if registered_items.any?
    return t("registration.user_registration.summary.details") if
      ineligible? || blocked? || full?
    return t("registration.user_registration.summary.change_preferences") if preferences_saved?
    return t("registration.user_registration.summary.choose") if campaign.preference_based?
    return t("registration.user_registration.summary.register") if exam_campaign?

    t("registration.user_registration.summary.show_and_register")
  end

  def cta_primary?
    summary_badge&.first == :warn
  end

  def exam_campaign?
    items.any? && items.all? { |item| item.registerable_type == "Exam" }
  end

  delegate :eligibility, :finalization_eligibility, :items, :item_preferences,
           to: :details

  def readonly?
    helpers.student_registration_readonly?(campaign)
  end

  def ineligible?
    !campaign.completed? && failed_ineligible_policies.any?
  end

  def failed_ineligible_policies
    @failed_ineligible_policies ||= failed_eligibility_policies(eligibility)
  end

  def failed_finalization_policies
    @failed_finalization_policies ||=
      if ineligible?
        []
      else
        failed_eligibility_policies(finalization_eligibility)
      end
  end

  def finalization_policy_warning?
    failed_finalization_policies.any?
  end

  def policy_overview_sections
    @policy_overview_sections ||=
      if eligibility.blank? && finalization_eligibility.blank?
        []
      else
        [
          policy_section(
            title: I18n.t("registration.user_registration.policy_overview." \
                          "registration_title"),
            description: I18n.t("registration.user_registration.policy_overview." \
                                "registration_description"),
            context: :registration,
            policies: eligibility
          ),
          policy_section(
            title: I18n.t("registration.user_registration.policy_overview." \
                          "finalization_title"),
            description: I18n.t("registration.user_registration.policy_overview." \
                                "finalization_description"),
            context: :finalization_warning,
            policies: finalization_eligibility
          )
        ]
      end
  end

  def policy_overview?
    policy_overview_sections.any?
  end

  def registration_actions_disabled?
    readonly? || ineligible? || blocked?
  end

  def blocked?
    return @blocked if defined?(@blocked)

    @blocked = !ineligible? && helpers.registration_campaign_blocked?(campaign, items)
  end

  def campaign_title
    campaign.student_facing_title
  end

  def instruction
    helpers.student_registration_instruction(campaign, items)
  end

  def policy_overview_hint(policy, context:)
    eligibility_policy_hint(policy, user: helpers.current_user, context: context)
  end

  private

    def risk_line
      return unless at_risk?
      return ineligible_line if ineligible?

      eligibility_failure_message(failed_finalization_policies.first,
                                  user: helpers.current_user, context: :finalization_warning)
    end

    def own_line
      if registered_items.any?
        return exam_line(registered_items.first.registerable) if exam_campaign?

        return registered_items.map { |item| item.registerable.title }.join(", ")
      end
      return unless preferences_saved?

      saved_preferences.map do |registration|
        rank = t("registration.user_registration.preference_rank_options." \
                 "#{registration.preference_rank}")
        "#{rank} #{registration.registration_item.registerable.title}"
      end.join(" · ")
    end

    def exam_line(exam)
      [exam.date && helpers.format_date(exam.date), exam.location.presence].compact.join(" · ")
    end

    def deadline_line
      deadline = campaign.registration_deadline
      days = (deadline.to_date - Time.zone.today).to_i
      soon = t("registration.user_registration.summary.days_left", count: days) if
        days.between?(0, 6)
      [t("registration.user_registration.summary.deadline",
         deadline: helpers.format_date(deadline)), soon].compact.join(" · ")
    end

    def ineligible_line
      policy = failed_ineligible_policies.first
      eligibility_failure_message(policy, user: helpers.current_user, context: :registration)
    end

    def mode_line
      if campaign.preference_based?
        t("registration.user_registration.summary.preference_mode",
          count: helpers.preference_rank_count(items), options: items.size)
      elsif exam_campaign?
        item = items.first
        free = item&.capacity && [item.capacity - item.item_capacity_used, 0].max
        free ? t("registration.user_registration.summary.exam_places", count: free) : nil
      else
        open = items.count(&:still_has_capacity?)
        t("registration.user_registration.summary.fcfs_mode", open: open, total: items.size)
      end
    end

    def failed_eligibility_policies(policies)
      policies.reject { |policy| policy.dig(:outcome, :pass) }
    end

    def policy_section(title:, description:, context:, policies:)
      {
        title: title,
        description: description,
        context: context,
        policies: policies
      }
    end
end
