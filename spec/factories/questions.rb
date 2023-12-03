# frozen_string_literal: true

FactoryBot.define do
  factory :question, parent: :medium, class: 'Question' do
    sort { 'Question' }

    transient do
      teachable_sort { :course }
      answers_count { 3 }
    end

    trait :with_stuff do
      text { Faker::Lorem.question }
      hint { Faker::Lorem.sentence }
      level { [0, 1, 2].sample }
      question_sort { 'mc' }
      independent { true }
    end

    trait :with_answers do
      after(:build) do |q, evaluator|
        q.answers = build_list(:answer, evaluator.answers_count,
                               :with_stuff, question: q)
      end
    end

    factory :valid_question, traits: [:with_description, :with_editors,
                                      :with_teachable]
  end
end
