FactoryGirl.define do
  factory :term do
    season 'WS'
    sequence(:year) { |n| 2000 + n }
    trait :summer do
      season 'SS'
    end
  end
end
