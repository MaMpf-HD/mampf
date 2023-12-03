# frozen_string_literal: true

FactoryBot.define do
  factory :medium_publisher do
    transient do
      medium_id { Faker::Number.between(from: 1, to: 20) }
      user_id { Faker::Number.between(from: 1, to: 20) }
      release_now { true }
      release_date do
        DateTime.now + 10 * Faker::Number.between(from: 0.0, to: 1.0)
      end
      release_for { "all" }
      lock_comments { false }
      vertices { false }
      create_assignment { false }
      assignment_title { "" }
      assignment_file_type { "" }
      assignment_deadline { nil }
      assignment_deletion_date { nil }
    end

    initialize_with do
      new(medium_id: medium_id, user_id: user_id, release_now: release_now,
          release_for: release_for,
          release_date: release_date, lock_comments: lock_comments,
          vertices: vertices,
          create_assignment: create_assignment,
          assignment_title: assignment_title,
          assignment_file_type: assignment_file_type,
          assignment_deadline: assignment_deadline,
          assignment_deletion_date: assignment_deletion_date)
    end
  end
end
