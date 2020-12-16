FactoryBot.define do
  factory :quiz_graph do
    trait :simple_linear do
      after(:build) do |q|
        questions = create_list(:question, 3, :with_answers)
      end
    end
  end
end