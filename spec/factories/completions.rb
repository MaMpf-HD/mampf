require "faker"

FactoryBot.define do
  factory :completion do
    user
    lecture

    association :completable, factory: :section

    trait :with_section do
      association :completable, factory: :section
    end

    trait :with_assignment do
      association :completable, factory: :assignment
    end
  end
end
