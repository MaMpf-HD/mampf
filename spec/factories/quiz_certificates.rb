FactoryBot.define do
  factory :quiz_certificate do
    quiz { nil }
    user { nil }
    code { "MyText" }
  end
end
