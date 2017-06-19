FactoryGirl.define do
  factory :tag, :aliases => [:related_tag] do
    sequence(:title) { |n| "Test Tag #{n}" }
    trait :with_related_tags do
      after(:build) { |t| t.related_tags = create_list(:tag, 2) }
    end
  end
end
