FactoryBot.define do
  factory :exam do
    association :lecture
    title { "#{Faker::Educator.subject} Exam #{Faker::Number.number(digits: 4)}" }

    # Far enough out that a registration deadline still fits in front of it.
    # The model derives one at `date - 3.days` and refuses it once it is in the
    # past, and specs set their own up to a week ahead — a plain
    # `Faker::Time.forward(days: 30)` drew inside that window often enough to
    # turn whole suite runs red at random.
    # An exam opens a registration process for itself; specs that build their
    # own campaign need it out of the way.
    trait :without_campaign do
      after(:create) { |exam| exam.registration_campaign&.destroy }
    end

    trait :with_date do
      date { Faker::Time.between(from: 14.days.from_now, to: 45.days.from_now) }
    end

    trait :written do
      with_date
      location { Faker::University.name }
    end

    trait :oral do
      date { nil }
      location { nil }
    end

    trait :with_capacity do
      capacity { Faker::Number.between(from: 50, to: 200) }
    end

    trait :unlimited do
      capacity { nil }
    end
  end
end
