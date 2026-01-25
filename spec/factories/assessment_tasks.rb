FactoryBot.define do
  factory :assessment_task, class: "Assessment::Task" do
    association :assessment, factory: :assessment, requires_points: true
    title { "Problem #{Faker::Number.between(from: 1, to: 10)}" }
    max_points { Faker::Number.between(from: 5, to: 20) }
    description { Faker::Lorem.paragraph }
    position { nil }
  end
end
