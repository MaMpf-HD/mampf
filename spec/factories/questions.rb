FactoryBot.define do
  factory :question, parent: :medium, class: 'Question' do
    sort { 'Question' }

    transient do
      teachable_sort { :course }
    end

    trait :with_stuff do
      text { Faker::Lorem.question }
      hint { Faker::Lorem.sentence }
      level { [0,1,2].sample }
      question_sort { 'mc' }
      independent { true }
    end

    factory :valid_question, traits: [:with_description, :with_editors,
                                      :with_teachable]
  end
end
