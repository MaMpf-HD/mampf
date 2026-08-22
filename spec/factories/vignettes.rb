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

  # ALPHABET is exactly 32 characters wide, so base 32 maps onto it directly.
  sequence :vignette_codename do |n|
    n.to_s(32)
     .upcase
     .tr("0123456789ABCDEFGHIJKLMNOPQRSTUV", Vignettes::Codename::ALPHABET)
     .rjust(Vignettes::Codename::LENGTH, Vignettes::Codename::ALPHABET[0])
  end

  factory :vignettes_questionnaire, class: "Vignettes::Questionnaire" do
    association :lecture, :with_vignettes
    title { generate(:vignette_title) }
    published { true }
    editable { true }

    trait :collecting do
      data_collection { true }
      consent_text { "We store your answers under the code you are given." }
    end
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
    pseudonym { generate(:vignette_codename) }
  end

  factory :vignettes_user_answer, class: "Vignettes::UserAnswer" do
    association :codename, factory: :vignettes_codename
    association :questionnaire, factory: :vignettes_questionnaire
  end

  factory :vignettes_text_answer, class: "Vignettes::TextAnswer" do
    association :user_answer, factory: :vignettes_user_answer
    association :slide, factory: :vignettes_slide
    association :question, factory: :vignettes_text_question
    text { "An answer" }
  end
end
