require 'faker'

FactoryBot.define do
  factory :tag, aliases: [:related_tag] do
    after(:build) { |t| t.notions << FactoryBot.build(:notion) }
  #  before(:build) { |n| n.notions = create_list(:notion,:with_tag_id, tag_id: :self.id, 1) }
  #  trait :with_related_tags do
  #    after(:build) { |t| t.related_tags = create_list(:tag, 2) }
  #  end
  #  trait :with_courses do
  #   after(:build) { |t| t.courses = create_list(:course, 2) }
  #  end
  end
end
