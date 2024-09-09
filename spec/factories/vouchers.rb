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

    trait :speaker do
      role { :speaker }
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
