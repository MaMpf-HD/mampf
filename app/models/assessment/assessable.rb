module Assessment
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
  end
end
