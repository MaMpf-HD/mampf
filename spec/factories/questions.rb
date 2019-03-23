FactoryBot.define do
  factory :question do
    text { "MyText" }
    label { "MyText" }
    hint { "MyText" }
    parent_id { 1 }
  end
end
