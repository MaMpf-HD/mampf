FactoryGirl.define do
  factory :connection do
    association :learning_asset
    association :linked_asset
  end
end
