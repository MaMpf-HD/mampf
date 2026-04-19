module Assessment
  module Pointable
    extend ActiveSupport::Concern
    include ::Assessment::Assessable

    def ensure_pointbook!(requires_submission: false)
      ensure_assessment!(
        requires_points: true,
        requires_submission: requires_submission
      )
    end
  end
end
