FactoryBot.define do
  factory :vtt_container do
    table_of_contents_data { "MyText" }
    references_data { "MyText" }
  end
end
