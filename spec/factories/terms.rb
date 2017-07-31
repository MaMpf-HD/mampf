FactoryGirl.define do
  factory :term do
    season 'WinterTerm'
    sequence(:year) { |n| 2000 + n }
    trait :summer do
      season 'SummerTerm'
    end
  end
end
