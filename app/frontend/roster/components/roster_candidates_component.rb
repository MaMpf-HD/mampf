# Renders a list of unassigned candidates for a given group type.
# Candidates are users who have registered in a campaign but are not assigned to any group.
class RosterCandidatesComponent < ViewComponent::Base
  def initialize(lecture:, group_type:)
    super()
    @lecture = lecture
    @group_type = group_type
  end

  def render?
    [:tutorials, :talks].include?(@group_type)
  end

  def candidates
    @candidates ||= fetch_candidates
  end

  private

    def fetch_candidates
      klass = case @group_type
              when :tutorials then Tutorial
              when :talks then Talk
              else return []
      end

      # Users already assigned to any group of this type in this lecture
      allocated_user_ids = klass.where(lecture: @lecture)
                                .joins(:members)
                                .pluck("users.id")
                                .uniq

      # Users registered in relevant campaigns
      campaign_ids = Registration::Campaign.where(campaignable: @lecture).pluck(:id)

      relevant_campaign_ids = Registration::Item.where(
        registration_campaign_id: campaign_ids,
        registerable_type: klass.name
      ).pluck(:registration_campaign_id).uniq

      candidate_user_ids = Registration::UserRegistration.where(
        registration_campaign_id: relevant_campaign_ids
      ).pluck(:user_id).uniq

      unassigned_ids = candidate_user_ids - allocated_user_ids

      User.where(id: unassigned_ids).order(:name, :email)
    end
end
