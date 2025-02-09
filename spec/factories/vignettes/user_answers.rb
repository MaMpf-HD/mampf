FactoryBot.define do
  factory :vignettes_user_answer, class: "Vignettes::UserAnswer" do
    user { nil }
    questionnaire { nil }
  end
end
