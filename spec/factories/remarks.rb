# frozen_string_literal: true

FactoryBot.define do
  factory :remark, parent: :medium, class: 'Remark' do
    sort { 'Remark' }

    transient do
      teachable_sort { :course }
    end

    trait :with_text do
      text { Faker::Lorem.question }
    end

    factory :valid_remark, traits: [:with_description, :with_editors,
                                    :with_teachable]
  end
end
