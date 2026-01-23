module Assessment
  class BaseController < ApplicationController
    before_action :check_feature_flag

    private

      def check_feature_flag
        return if Flipper.enabled?(:assessment_grading)

        redirect_to root_path, alert: I18n.t("assessment.errors.feature_not_available")
      end
  end
end
