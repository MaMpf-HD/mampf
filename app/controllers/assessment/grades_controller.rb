module Assessment
  class GradesController < ApplicationController
    before_action :set_assessment
    before_action :set_task
    before_action :set_locale

    def current_ability
      @current_ability ||= AssessmentAbility.new(current_user)
    end

    # Save grade for a single participation
    def update
      grade = params[:grade]
      participation = Participation.find(params[:participation_id])

      GradeEntryService.set_grade(participation, grade, current_user)

      render json: { success: true, grade: participation.grade }
    end
  end
end
