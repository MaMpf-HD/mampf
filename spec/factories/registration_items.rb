FactoryBot.define do
  factory :registration_item, class: "Registration::Item" do
    # An item takes only groups of its campaign's lecture: without a campaign
    # named, it gets one of the group's own lecture.
    registration_campaign { nil }

    transient do
      lecture { registration_campaign&.campaignable || association(:lecture) }
    end

    registerable { association(:tutorial, lecture: lecture) }

    after(:build) do |item|
      item.registration_campaign ||=
        build(:registration_campaign, campaignable: item.registerable.lecture)
    end

    trait :for_tutorial do
      registerable { association(:tutorial, lecture: lecture) }
    end

    trait :for_talk do
      registration_campaign do
        association(:registration_campaign, campaignable: association(:seminar))
      end
      registerable { association(:talk, lecture: lecture) }
    end

    trait :for_cohort do
      registerable { association(:cohort, context: lecture) }
    end
  end
end
