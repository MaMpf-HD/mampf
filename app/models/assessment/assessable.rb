module Assessment
  module Assessable
    extend ActiveSupport::Concern

    included do
      has_one :assessment, as: :assessable, dependent: :destroy,
                           class_name: "Assessment::Assessment"
    end

    def ensure_assessment!(requires_points:, requires_submission: false,
                           visible_from: nil, due_at: nil)
      a = assessment || build_assessment
      a.requires_points = requires_points
      a.requires_submission = requires_submission
      a.visible_from = visible_from if visible_from
      a.due_at = due_at if due_at
      a.lecture ||= try(:lecture)
      a.save! if a.changed?
      a
    end

    def seed_participations_from_roster!
      raise(NotImplementedError,
            "#{self.class.name} must implement seed_participations_from_roster!")
    end
  end
end
