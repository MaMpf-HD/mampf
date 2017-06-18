FactoryGirl.define do
  factory :term do
    type ["WinterTerm", "SummerTerm"].sample
    year (2010..2030).to_a.sample
  end
end
