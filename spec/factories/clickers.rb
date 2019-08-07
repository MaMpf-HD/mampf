FactoryBot.define do
  factory :clicker do
    editor_id { 1 }
    teachable { nil }
    question_id { 1 }
    code { "MyText" }
  end
end
