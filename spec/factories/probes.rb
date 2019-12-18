FactoryBot.define do
  factory :probe do
    question_id { 1 }
    quiz_id { 1 }
    correct { false }
    session_id { "MyText" }
  end
end
