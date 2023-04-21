# frozen_string_literal: true

FactoryBot.define do
  factory :probe do
    trait :with_stuff do
      question_id { Faker::Number.number }
      quiz_id { Faker::Number.number }
      correct { [true, false].sample }
      session_id { Faker::Crypto.md5 }
      progress { [-1, 1, 2, 3].sample }
      success do
        if progress == -1
          [1, 2, 3].sample
        else
          (1..progress).to_a.sample
        end
      end
    end
  end
end
