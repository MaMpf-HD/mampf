module Assessment
  class Assessment < ApplicationRecord
    belongs_to :assessable, polymorphic: true
    belongs_to :lecture

    has_many :tasks, dependent: :destroy, class_name: "Assessment::Task",
                     inverse_of: :assessment
    has_many :assessment_participations, dependent: :destroy,
                                         class_name: "Assessment::Participation",
                                         inverse_of: :assessment
    has_many :task_points, through: :assessment_participations,
                           class_name: "Assessment::TaskPoint"

    enum :status, { draft: 0, open: 1, closed: 2, graded: 3, archived: 4 }

    validates :title, presence: true

    def seed_participations_from!(user_ids:, tutorial_mapping: {})
      existing = assessment_participations.pluck(:user_id).to_set
      new_user_ids = user_ids.reject { |uid| existing.include?(uid) }

      return if new_user_ids.empty?

      participations_data = new_user_ids.map do |user_id|
        {
          assessment_id: id,
          user_id: user_id,
          tutorial_id: tutorial_mapping[user_id],
          status: 0,
          points_total: 0.0,
          created_at: Time.current,
          updated_at: Time.current
        }
      end

      # rubocop:disable Rails/SkipsModelValidations
      Participation.insert_all(participations_data)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end
end
