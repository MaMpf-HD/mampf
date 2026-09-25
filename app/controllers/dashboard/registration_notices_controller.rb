module Dashboard
  # Dismisses a rejected registration's notice from a lecture's dashboard
  # card. The registration itself is kept for auditing - only the notice
  # about it is hidden, optionally in exchange for a plain bookmark.
  class RegistrationNoticesController < ApplicationController
    include Dashboard::BoardRenderer

    before_action :set_lecture

    def destroy
      return head(:not_found) unless @lecture
      return head(:forbidden) if keep_bookmarked? && !current_user.may_unlock_lecture?(@lecture)

      rejected_registrations.find_each(&:dismiss!)
      if keep_bookmarked?
        current_user.unlock_lecture!(@lecture)
      else
        current_user.unbookmark_lecture!(@lecture)
      end
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
          registration_campaign: @lecture.registration_campaigns.non_exam
        ).rejected.not_dismissed
      end
  end
end
