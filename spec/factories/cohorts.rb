FactoryBot.define do
  factory :cohort do
    title { "Repeaters Linear Algebra 1" }
    description do
      "If you failed last year's exam and don't want to go through tutorials again, register here."
    end
    capacity { 20 }
    association :context, factory: :lecture
  end
end
