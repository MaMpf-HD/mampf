FactoryBot.define do
  factory :voucher do
    role { :tutor }
    association :lecture

    trait :tutor do
      role { :tutor }
    end

    trait :editor do
      role { :editor }
    end

    trait :teacher do
      role { :teacher }
    end

    # No longer issued (speakers come through registration), so the role
    # guard is stepped around to get one that is still in circulation.
    trait :speaker do
      role { :speaker }
      to_create do |voucher|
        voucher.define_singleton_method(:ensure_role_valid_for_lecture) { nil }
        voucher.save!
      end
    end

    trait :expired do
      after(:create) do |voucher|
        voucher.update(expires_at: 1.day.ago)
      end
    end

    trait :invalidated do
      invalidated_at { 1.day.ago }
    end
  end
end
