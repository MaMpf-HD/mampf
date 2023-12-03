FactoryBot.define do
  factory :section do
    association :chapter
    title do
      "#{Faker::Book.title} #{Faker::Number.between(from: 1, to: 9999)}"
    end
  end
end
