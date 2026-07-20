module Assessment
  # Represents the common interface for any model that can be assessed.
  module Assessable
    extend ActiveSupport::Concern

    included do
      has_one :assessment, as: :assessable, dependent: :destroy,
                           class_name: "Assessment::Assessment"
    end

    def ensure_assessment!(requires_points:, requires_submission: false)
      a = assessment || build_assessment
      a.requires_points = requires_points
      a.requires_submission = requires_submission
      a.lecture ||= try(:lecture)
      a.save! if a.changed?
      a
    end

    # By default, grading is always open unless the specific assessable
    # (like Assignment) overrides this.
    def grading_open?
      true
    end
  end
end
