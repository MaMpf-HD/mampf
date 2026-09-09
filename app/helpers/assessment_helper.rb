# Helpers for the assessment area of the lecture edit page.
module AssessmentHelper
  # The assessment tab shows the overview of all assessables, or the dashboard
  # of the one the URL names. The latter is what makes a dashboard link work
  # when it is opened in a new tab instead of clicked.
  def assessment_frame_src(lecture)
    return overview_frame_src(lecture) if params[:assessment_id].blank?

    assessment_assessment_path(params[:assessment_id],
                               assessable_type: params[:assessable_type],
                               assessable_id: params[:assessable_id],
                               tab: params[:assessment_tab])
  end

  private

    def overview_frame_src(lecture)
      assessment_assessments_path(lecture_id: lecture.id,
                                  tab: params[:assessment_tab])
    end
end
