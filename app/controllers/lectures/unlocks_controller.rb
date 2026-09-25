module Lectures
  # Unlocks a passphrase-protected lecture from its home page. The unlock is
  # stored as a bookmark (see Lecture#unlocked_for?).
  class UnlocksController < ApplicationController
    # A passphrase is shared by the whole lecture, so guessing it is throttled.
    rate_limit to: 10, within: 1.minute, only: :create,
               by: -> { current_user&.id || request.remote_ip },
               with: lambda {
                 redirect_to(lecture_home_path(params[:lecture_id]),
                             alert: t("registration.lecture.home.unlock_too_many_attempts"),
                             status: :see_other)
               }

    before_action :set_lecture

    def create
      unless @lecture.published? || current_user.admin ||
             @lecture.edited_by?(current_user)
        return redirect_to(root_path, alert: t("admin.lecture.no_rights"),
                                      status: :see_other)
      end

      unless @lecture.bookmarkable_by?(current_user) || passphrase_matches?
        return redirect_to(lecture_home_path(@lecture),
                           alert: t("errors.profile.passphrase"),
                           status: :see_other)
      end

      current_user.bookmark_lecture!(@lecture)
      current_user.touch # busts the cached navbar/favorites
      redirect_to lecture_path(@lecture), status: :see_other
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
        return if @lecture

        redirect_to root_path, alert: t("controllers.no_lecture"), status: :see_other
      end

      def passphrase_matches?
        @lecture.passphrase.present? &&
          ActiveSupport::SecurityUtils.secure_compare(@lecture.passphrase,
                                                      params[:passphrase].to_s)
      end
  end
end
