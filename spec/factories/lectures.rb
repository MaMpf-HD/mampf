FactoryBot.define do
  factory :lecture do
    association :course, factory: [:course, :with_tags]
    association :teacher, factory: :user
    released { ['all', 'users', 'subscribers', nil].sample }
    after(:build) do |user, _evaluator|
      user.editors << build(:user)
    end
    content_mode { ['video', 'manuscript'].sample }
    sort do
      ['lecture', 'seminar', 'oberseminar',
       'proseminar', 'special'].sample
    end
    association :term
    trait :with_disabled_tags do
      after(:build) { |l| l.disabled_tags = l.course.tags.sample(2) }
    end
    trait :published_to_all do
      released {'all'}
    end
    trait :with_additional_tags do
      after(:build) { |l| l.additional_tags = create_list(:tag, 2) }
    end
  end
end
