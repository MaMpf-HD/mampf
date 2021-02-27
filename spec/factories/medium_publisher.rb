FactoryBot.define do
  factory :medium_publisher do
    transient do
      medium_id { Faker::Number.between(from: 1, to: 20) }
      user_id { Faker::Number.between(from: 1, to: 20) }
      release_date { DateTime.now +
                     10 * Faker::Number.between(from: 0.0, to: 1.0) }
      release_for { 'all' }
      lock_comments { false }
      vertices { false }
    end

    initialize_with { new(medium_id: medium_id, release_for: release_for,
                          release_date: release_date,
                          lock_comments: lock_comments, vertices: vertices,
                          user_id: user_id) }
  end
end