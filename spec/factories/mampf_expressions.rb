# frozen_string_literal: true

FactoryBot.define do
  factory :mampf_expression do
    transient do
      a_0 { Faker::Number.between(from: 1, to: 100) }
      value { "t^2+#{a_0}" }
      tex { "t^2+#{a_0}" }
      nerd { "t^2+#{a_0}" }
    end

    initialize_with { new(value, tex, nerd) }
  end
end
