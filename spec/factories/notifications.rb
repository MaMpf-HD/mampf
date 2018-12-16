FactoryBot.define do
  factory :notification do
    recipient_id { 1 }
    notifiable_id { 1 }
    notifiable_type { "MyText" }
    action { "MyText" }
  end
end
