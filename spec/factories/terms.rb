FactoryGirl.define do
  factory :term do
    season 'Winter'
    sequence(:year) { |n| 2000 + n }
    trait :summer do
      season 'Summer'
    end
  end
end
