module Lectures
  # Ends the current user's participation in a lecture from its home page,
  # see Rosters::LectureLeave.
  class MembershipsController < ApplicationController
    before_action :set_lecture

    def destroy
      leave = Rosters::LectureLeave.new(@lecture, current_user)
      unless leave.confirmed?(params[:confirmation])
        return redirect_to(lecture_home_path(@lecture),
                           alert: t("lecture_home.leave.not_confirmed"),
                           status: :see_other)
      end

      leave.leave!
      redirect_to lecture_home_path(@lecture),
                  notice: t("lecture_home.leave.done", lecture: @lecture.title_term_info_no_type),
                  status: :see_other
    rescue Rosters::LectureLeave::NotParticipatingError
      current_user.unbookmark_lecture!(@lecture)
      redirect_to lecture_home_path(@lecture),
                  notice: t("lecture_home.leave.not_participating",
                            lecture: @lecture.title_term_info_no_type),
                  status: :see_other
    rescue Rosters::LectureLeave::NotAllowedError
      redirect_to lecture_home_path(@lecture),
                  alert: t("lecture_home.leave.not_allowed"),
                  status: :see_other
    rescue ActiveRecord::Deadlocked
      redirect_to lecture_home_path(@lecture),
                  alert: t("lecture_home.leave.failed"),
                  status: :see_other
    end

    private

      def set_lecture
        @lecture = Lecture.find_by(id: params[:lecture_id])
        return if @lecture

        redirect_to root_path, alert: t("controllers.no_lecture"), status: :see_other
      end
  end
end
