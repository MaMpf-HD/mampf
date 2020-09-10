FactoryBot.define do
  factory :assignment do
    lecture { nil }
    medium { nil }
    title { "MyText" }
    deadline { "2020-09-10 10:11:27" }
  end
end
