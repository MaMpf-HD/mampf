FactoryBot.define do
  factory :vtt_container do
    trait :with_table_of_contents do
      after(:build) do |v|
        v.table_of_contents = File.open("#{SPEC_FILES}/toc.vtt", "rb")
      end
    end

    trait :with_references do
      after(:build) do |v|
        v.references = File.open("#{SPEC_FILES}/references.vtt", "rb")
      end
    end
  end
end
