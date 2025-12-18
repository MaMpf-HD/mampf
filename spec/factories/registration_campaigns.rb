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
      status { :draft }
      with_items
      after(:create) do |campaign|
        campaign.update!(status: :open)
      end
    end

    trait :closed do
      status { :closed }
      registration_deadline { 1.day.ago }
      with_items
    end

    trait :closed_only do
      status { :closed }
      registration_deadline { 1.day.ago }
    end

    trait :processing do
      status { :processing }
      registration_deadline { 1.day.ago }
      with_items
    end

    trait :processing_only do
      status { :processing }
      registration_deadline { 1.day.ago }
    end

    trait :completed do
      status { :completed }
      registration_deadline { 2.weeks.ago }
      with_items
    end

    trait :completed_after_policies do
      status { :draft }
      registration_deadline { 2.weeks.ago }
      with_items
      with_policies
      after(:create) do |campaign|
        campaign.update!(status: :completed)
      end
    end

    trait :planning_only do
      planning_only { true }
    end

    trait :with_items do
      transient do
        self_registerable { false }
        capacity { nil }
      end
      after(:create) do |campaign, evaluator|
        lecture = campaign.campaignable

        self_registerable = evaluator.self_registerable

        if self_registerable
          create(:registration_item,
                 registration_campaign: campaign,
                 registerable: lecture)

        elsif lecture.seminar?
          talks = create_list(:talk, 3, lecture: lecture)
          talks.each do |talk|
            create(:registration_item,
                   registration_campaign: campaign,
                   registerable: talk)
          end
        else
          capacity = evaluator.capacity if evaluator.capacity
          tutorials = create_list(:tutorial, 3, lecture: lecture, capacity: capacity)
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

    trait :with_policies do
      after(:build) do |campaign|
        create(:registration_policy, :institutional_email,
               registration_campaign: campaign)
      end
    end

    trait :with_prerequisite_policy do
      transient do
        parent_campaign { nil }
        parent_campaign_id { nil }
      end

      after(:build) do |child_campaign, evaluator|
        # parent_campaign&.id is for backend test and parent_campaign_id is for
        # frontend test
        id = evaluator.parent_campaign&.id || evaluator.parent_campaign_id
        raise ArgumentError, "parent_campaign must be provided" unless id

        create(:registration_policy,
               :prerequisite_campaign,
               registration_campaign: child_campaign,
               config: { "prerequisite_campaign_id" => id })
      end
    end

    trait :with_first_item_registered do
      transient do
        user_id { nil }
      end
      after(:create) do |campaign, evaluator|
        item = campaign.registration_items.first
        user = User.find(evaluator.user_id) if evaluator.user_id
        create(:registration_user_registration,
               :fcfs,
               registration_item: item,
               registration_campaign: campaign,
               user: user)
      end
    end
  end
end
