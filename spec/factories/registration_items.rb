FactoryBot.define do
  factory :registration_item, class: "Registration::Item" do
    registration_campaign { association(:registration_campaign) }

    transient do
      lecture { registration_campaign.campaignable }
    end

    registerable { association(:tutorial, lecture: lecture) }

    trait :for_tutorial do
      registerable { association(:tutorial, lecture: lecture) }
    end

    trait :for_talk do
      registerable { association(:talk, lecture: lecture) }
    end

    trait :for_cohort do
      registerable { association(:cohort, context: lecture) }
    end
  end
end
