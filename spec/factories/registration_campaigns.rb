FactoryBot.define do
  factory :registration_campaign, class: "Registration::Campaign" do
    association :campaignable, factory: :lecture
    description { "#{Faker::Company.buzzword} Registration" }
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
      after(:create) do |campaign|
        create(:registration_policy, :institutional_email,
               registration_campaign: campaign)
      end
    end
  end
end
