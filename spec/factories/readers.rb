FactoryBot.define do
  factory :reader do
    association :user, factory: :confirmed_user
    thread { Commontator::Thread.new }
  end
end
