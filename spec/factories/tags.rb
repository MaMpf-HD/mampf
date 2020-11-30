require 'faker'

FactoryBot.define do
  factory :tag, aliases: [:related_tag] do
    after(:build) { |t| t.notions << FactoryBot.build(:notion) }
  end

end
