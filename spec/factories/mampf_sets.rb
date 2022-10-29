# frozen_string_literal: true

FactoryBot.define do
  factory :mampf_set do
    transient do
      a_1 { Faker::Number.between(from: -3, to: 3).to_s }
      a_2 { Faker::Number.between(from: -3, to: 3).to_s }
      a_3 { Faker::Number.between(from: -3, to: 3).to_s }
      value { "#{a_1},#{a_2},#{a_3}" }
      tex { "\\{#{a_1},#{a_2},#{a_3}\\}" }
      nerd { "vector(#{a_1},#{a_2},#{a_3})" }
    end

    initialize_with { new(value, tex, nerd) }
  end
end
