module Assessment
  # Makes an assessable carry a final grade — a talk, an exam — as opposed to
  # only points. The grade lands on the participation, not here.
  module Gradable
    extend ActiveSupport::Concern
    include ::Assessment::Assessable

    def ensure_gradebook!
      requires_points = assessment&.requires_points
      ensure_assessment!(
        requires_points: requires_points || false,
        requires_submission: false
      )
    end
  end
end
