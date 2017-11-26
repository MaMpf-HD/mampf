FactoryBot.define do
  factory :connection do
    association :lecture
    association :preceding_lecture
  end
end
