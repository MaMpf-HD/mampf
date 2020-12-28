# frozen_string_literal: true

FactoryBot.define do
  factory :mampf_matrix do
    transient do
      row_count { 2 }
      column_count { 2 }
      a_11 { Faker::Number.between(from: -3, to: 3).to_s }
      a_12 { Faker::Number.between(from: -3, to: 3).to_s }
      a_21 { Faker::Number.between(from: -3, to: 3).to_s }
      a_22 { Faker::Number.between(from: -3, to: 3).to_s }
      coefficients { [a_11, a_12, a_21, a_22] }
      tex { "\\begin{pmatrix} #{a_11} & #{a_12} \\cr " +
            "#{a_21} & #{a_22} \\end{pmatrix}" }
      nerd { "matrix([#{a_11},#{a_12}],[#{a_21},#{a_22}]" }
    end

    initialize_with { new(row_count, column_count, coefficients, tex, nerd) }
  end
end
