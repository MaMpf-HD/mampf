module Dashboard
  # Dismisses a rejected registration's notice from a lecture's dashboard
  # card. The registration itself is kept for auditing - only the notice
  # about it is hidden, optionally in exchange for a plain bookmark.
  class RegistrationNoticesController < ApplicationController
    include Dashboard::RendersBoard

    before_action :set_lecture

    def destroy
      return head(:not_found) unless @lecture

      rejected_registrations.find_each(&:dismiss!)
      current_user.subscribe_lecture!(@lecture) if keep_bookmarked?
      current_user.touch
      render_board
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
      end

      def keep_bookmarked?
        ActiveModel::Type::Boolean.new.cast(params[:keep_bookmarked])
      end

      def rejected_registrations
        Registration::UserRegistration.where(
          user: current_user,
          registration_campaign: @lecture.registration_campaigns
        ).rejected.not_dismissed
      end
  end
end
