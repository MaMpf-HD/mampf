# frozen_string_literal: true

FactoryBot.define do
  factory :vtt_container do
    trait :with_table_of_contents do
      after(:build) do |v|
        v.table_of_contents = File.open('spec/files/toc.vtt', 'rb')
      end
    end

    trait :with_references do
      after(:build) do |v|
        v.references = File.open('spec/files/references.vtt', 'rb')
      end
    end
  end
end
