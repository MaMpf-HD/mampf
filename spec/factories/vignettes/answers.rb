FactoryBot.define do
  factory :vignettes_answer, class: 'Vignettes::Answer' do
    type { "" }
    question { nil }
    slide { nil }
  end
end
