require 'faker'

FactoryGirl.define do
  factory :tag do
    title { Faker::Book.title }
    factory :tag_with_relations do
      after(:create) { |t| t.related_tags = create_list(:tag,2) }
    end
  end
end
