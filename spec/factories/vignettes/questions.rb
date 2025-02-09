FactoryBot.define do
  factory :vignettes_question, class: "Vignettes::Question" do
    type { "" }
    question_text { "MyText" }
    slide { nil }
  end
end
