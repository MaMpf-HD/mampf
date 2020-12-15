FactoryBot.define do
  factory :quiz, parent: :medium, class: 'Quiz' do
    sort { 'Quiz' }

    transient do
      teachable_sort { :course }
    end

    factory :valid_quiz, traits: [:with_description, :with_editors,
                                  :with_teachable]

    factory :valid_random_quiz, traits: [:with_description] do
      sort { 'RandomQuiz' }
    end
  end
end
