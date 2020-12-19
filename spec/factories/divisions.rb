FactoryBot.define do
  factory :division do
    association :program
    name { Faker::IndustrySegments.sub_sector }
  end
end
