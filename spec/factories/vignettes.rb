FactoryBot.define do
  sequence :vignette_title do |n|
    "Vignette #{n}"
  end

  sequence :vignette_slide_title do |n|
    "Slide #{n}"
  end

  sequence :vignette_slide_position do |n|
    n
  end

  sequence :vignette_option_text do |n|
    "Option #{n}"
  end

  sequence :vignette_codename do |n|
    "codename#{n}"
  end

  factory :vignettes_questionnaire, class: "Vignettes::Questionnaire" do
    association :lecture
    title { generate(:vignette_title) }
    published { true }
    editable { true }
  end

  factory :vignettes_slide, class: "Vignettes::Slide" do
    association :questionnaire, factory: :vignettes_questionnaire
    title { generate(:vignette_slide_title) }
    position { generate(:vignette_slide_position) }
    content { "Slide content" }
  end

  factory :vignettes_text_question, class: "Vignettes::TextQuestion" do
    association :slide, factory: :vignettes_slide
    question_text { "Enter your answer" }
  end

  factory :vignettes_number_question, class: "Vignettes::NumberQuestion" do
    association :slide, factory: :vignettes_slide
    question_text { "Enter a number" }
    only_integer { false }
  end

  factory :vignettes_multiple_choice_question,
          class: "Vignettes::MultipleChoiceQuestion" do
    association :slide, factory: :vignettes_slide
    question_text { "Pick one option" }
  end

  factory :vignettes_likert_scale_question,
          class: "Vignettes::LikertScaleQuestion" do
    association :slide, factory: :vignettes_slide
    question_text { "How much do you agree?" }
    language { "en" }
  end

  factory :vignettes_option, class: "Vignettes::Option" do
    association :question, factory: :vignettes_multiple_choice_question
    text { generate(:vignette_option_text) }
  end

  factory :vignettes_info_slide, class: "Vignettes::InfoSlide" do
    association :questionnaire, factory: :vignettes_questionnaire
    title { "Info Slide" }
    icon_type { "eye" }
    content { "Info content" }
  end

  factory :vignettes_codename, class: "Vignettes::Codename" do
    association :user, factory: :confirmed_user
    association :lecture
    pseudonym { generate(:vignette_codename) }
  end

  factory :vignettes_user_answer, class: "Vignettes::UserAnswer" do
    association :user, factory: :confirmed_user
    association :questionnaire, factory: :vignettes_questionnaire
  end
end
