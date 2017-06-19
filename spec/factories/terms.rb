FactoryGirl.define do
  factory :term do
    type 'WinterTerm'
    sequence(:year) { |n| 2000+n }
    trait :summer do
      type 'SummerTerm'
    end
  end
end
