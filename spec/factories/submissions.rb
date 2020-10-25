FactoryBot.define do
  factory :submission do
    tutorial { nil }
    assignment { nil }
    token { "MyText" }
  end
end
