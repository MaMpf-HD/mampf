FactoryBot.define do
  factory :registration_campaign, class: "Registration::Campaign" do
    association :campaignable, factory: :lecture, capacity: 100
    title { "#{Faker::Company.buzzword} Registration" }
    allocation_mode { :first_come_first_served }
    registration_deadline { 2.weeks.from_now }
    status { :draft }
    planning_only { false }

    trait :first_come_first_served do
      allocation_mode { :first_come_first_served }
    end

    trait :preference_based do
      allocation_mode { :preference_based }
    end

    trait :open do
      status { :open }
    end

    trait :closed do
      status { :closed }
      registration_deadline { 1.day.ago }
    end

    trait :processing do
      status { :processing }
      registration_deadline { 1.day.ago }
    end

    trait :completed do
      status { :completed }
      registration_deadline { 2.weeks.ago }
    end

    trait :planning_only do
      planning_only { true }
    end

    trait :with_items do
      after(:create) do |campaign|
        lecture = campaign.campaignable
        if lecture.seminar?
          talks = create_list(:talk, 3, lecture: lecture)
          talks.each do |talk|
            create(:registration_item,
                   registration_campaign: campaign,
                   registerable: talk)
          end
        else
          tutorials = create_list(:tutorial, 3, lecture: lecture)
          tutorials.each do |tutorial|
            create(:registration_item,
                   registration_campaign: campaign,
                   registerable: tutorial)
          end
        end
      end
    end

    trait :for_seminar do
      association :campaignable, factory: [:lecture, :is_seminar]
      title { "Seminar Talk Registration" }
      allocation_mode { :first_come_first_served }
    end

    trait :no_capacity_remained_first_item do
      after(:create) do |campaign|
        campaign.registration_items.first.registerable.update!(capacity: 0)
      end
    end

    trait :for_lecture_enrollment do
      title { "Lecture Enrollment" }
      allocation_mode { :first_come_first_served }

      after(:create) do |campaign|
        lecture = campaign.campaignable
        create(:registration_item,
               registration_campaign: campaign,
               registerable: lecture)
      end
    end

    trait :for_tutorial_enrollment do
      title { "Tutorial Enrollment" }

      after(:create) do |campaign|
        lecture = campaign.campaignable

        tutorial1 = create(:tutorial, lecture: lecture, capacity: 100)
        tutorial2 = create(:tutorial, lecture: lecture, capacity: 100)

        create(:registration_item,
               registration_campaign: campaign,
               registerable: tutorial1)
        create(:registration_item,
               registration_campaign: campaign,
               registerable: tutorial2)
      end
    end

    trait :for_talk_enrollment do
      title { "Talk Enrollment" }

      after(:create) do |campaign|
        lecture = campaign.campaignable

        talk1 = create(:talk, lecture: lecture, capacity: 2)
        talk2 = create(:talk, lecture: lecture, capacity: 2)

        create(:registration_item,
               registration_campaign: campaign,
               registerable: talk1)
        create(:registration_item,
               registration_campaign: campaign,
               registerable: talk2)
      end
    end

    trait :with_policies do
      after(:create) do |campaign|
        create(:registration_policy, :institutional_email,
               registration_campaign: campaign)
      end
    end

    trait :with_prerequisite_policy do
      transient do
        parent_campaign { nil }
        parent_campaign_id { nil }
      end

      after(:create) do |child_campaign, evaluator|
        # parent_campaign&.id is for BE test and parent_campaign_id is for FE test
        id = evaluator.parent_campaign&.id || evaluator.parent_campaign_id
        raise ArgumentError, "parent_campaign must be provided" unless id

        create(:registration_policy,
               :prerequisite_campaign,
               registration_campaign: child_campaign,
               config: { "prerequisite_campaign_id" => id })
      end
    end
  end
end
