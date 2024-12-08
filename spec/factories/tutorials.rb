FactoryBot.define do
  factory :tutorial do
    association :lecture
    title { "#{Faker::Movie.title} #{Faker::Number.number}" }
  end

  trait :with_tutors do
    transient do
      tutors_count { 1 }
    end
    after :build do |t, evaluator|
      t.tutors = build_list(:confirmed_user, evaluator.tutors_count)
    end
  end

  trait :with_tutor_by_id do
    transient do
      tutor_id { nil }
    end
    after :build do |t, eval|
      t.tutors = [User.find(eval.tutor_id)]
    end
  end
end
