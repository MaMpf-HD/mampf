FactoryBot.define do
  factory :course_tag_join do
    association :tag
    association :course
  end
end
