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
        sort = evaluator.notifiable_sort.downcase.to_sym
        # only lecture announcements notify anybody
        traits = sort == :announcement ? [:with_lecture] : []
        n.notifiable = build(sort, *traits)
      end
    end
  end
end
