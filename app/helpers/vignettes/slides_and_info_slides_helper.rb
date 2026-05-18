module Vignettes
  module SlidesAndInfoSlidesHelper
    def turbo_slide_edit_url(slide)
      if slide.is_a?(Vignettes::InfoSlide)
        edit_questionnaire_info_slide_path(slide.questionnaire, slide)
      else
        edit_questionnaire_slide_path(slide.questionnaire, slide)
      end
    end
  end
end
