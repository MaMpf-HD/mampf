FactoryBot.define do
  factory :assessment_grade_scheme, class: "Assessment::GradeScheme" do
    association :assessment, factory: [:assessment, :for_exam]
    kind { :banded }
    active { true }
    config do
      {
        "bands" => [
          { "min_points" => 54, "grade" => "1.0" },
          { "min_points" => 48, "grade" => "1.3" },
          { "min_points" => 42, "grade" => "1.7" },
          { "min_points" => 36, "grade" => "2.0" },
          { "min_points" => 33, "grade" => "2.3" },
          { "min_points" => 30, "grade" => "3.0" },
          { "min_points" => 27, "grade" => "3.7" },
          { "min_points" => 24, "grade" => "4.0" },
          { "min_points" => 0,  "grade" => "5.0" }
        ]
      }
    end

    trait :percentage do
      config do
        {
          "bands" => [
            { "min_pct" => 90,  "max_pct" => 100, "grade" => "1.0" },
            { "min_pct" => 80,  "max_pct" => 89.99, "grade" => "1.3" },
            { "min_pct" => 70,  "max_pct" => 79.99, "grade" => "1.7" },
            { "min_pct" => 60,  "max_pct" => 69.99, "grade" => "2.0" },
            { "min_pct" => 55,  "max_pct" => 59.99, "grade" => "2.3" },
            { "min_pct" => 50,  "max_pct" => 54.99, "grade" => "3.0" },
            { "min_pct" => 45,  "max_pct" => 49.99, "grade" => "3.7" },
            { "min_pct" => 40,  "max_pct" => 44.99, "grade" => "4.0" },
            { "min_pct" => 0,   "max_pct" => 39.99, "grade" => "5.0" }
          ]
        }
      end
    end

    trait :draft do
      active { false }
    end

    trait :applied do
      applied_at { 1.hour.ago }
      association :applied_by, factory: :confirmed_user
    end
  end
end
