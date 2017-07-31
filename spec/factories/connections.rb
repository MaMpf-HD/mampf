FactoryGirl.define do
  factory :connection do
    association :asset
    association :linked_asset
  end
end
