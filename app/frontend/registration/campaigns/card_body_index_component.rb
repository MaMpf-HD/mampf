class CardBodyIndexComponent < ViewComponent::Base
  attr_reader :lecture, :new_campaign, :selected_section

  def initialize(lecture:, new_campaign: nil, registration_section: nil)
    super()
    @lecture = lecture
    @new_campaign = new_campaign
    @selected_section = normalize_registration_section(registration_section)
  end

  def active_campaigns
    @active_campaigns ||= campaigns.reject(&:completed?)
  end

  def completed_campaigns
    @completed_campaigns ||= campaigns.select(&:completed?)
  end

  def no_campaign_groups
    @no_campaign_groups ||= Rosters::NoCampaignRegisterablesQuery.new(lecture).call
  end

  def campaign_section_id
    "registration_campaign_section_#{lecture.id}"
  end

  def no_campaign_section_id
    "no_registration_campaign_section_#{lecture.id}"
  end

  def show_section_choice?
    campaigns.empty? && no_campaign_groups.empty? && selected_section.blank?
  end

  def collapse_campaign_section?
    selected_section == "no_campaign" ||
      (active_campaigns.empty? && no_campaign_groups.any?)
  end

  def collapse_no_campaign_section?
    selected_section == "campaign" ||
      (campaigns.any? && no_campaign_groups.empty?)
  end

  private

    def campaigns
      @campaigns ||= lecture.registration_campaigns.order(created_at: :desc).to_a
    end

    def normalize_registration_section(section)
      section.to_s.presence_in(["campaign", "no_campaign"])
    end
end
