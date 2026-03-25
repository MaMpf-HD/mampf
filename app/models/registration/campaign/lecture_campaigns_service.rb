module Registration
  class Campaign
    class LectureCampaignsService
      def initialize(lecture, user)
        @lecture = lecture
        @user = user
      end

      def call
        campaigns = Registration::Campaign
                    .where(campaignable_id: @lecture.id)
                    .where.not(status: :draft)

        campaigns.map do |campaign|
          CampaignDetailsService.new(campaign, @user).call
        end
      end
    end
  end
end
