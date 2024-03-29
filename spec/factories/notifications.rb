FactoryBot.define do
  factory :notification do
    association :recipient, factory: :confirmed_user

    trait :with_notifiable do
      transient do
        notifiable_sort do
          ["Medium", "Course", "Lecture", "Announcement"].sample
        end
      end
      after :build do |n, evaluator|
        n.notifiable = build(evaluator.notifiable_sort.downcase.to_sym)
      end
    end
  end
end
