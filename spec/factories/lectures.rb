FactoryGirl.define do
  factory :lecture do
    association :course
    association :teacher
    association :term
  end
end
