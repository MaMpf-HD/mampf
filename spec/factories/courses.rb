FactoryBot.define do
  factory :course do
    title do
      "#{Faker::Book.title.gsub("&", "and")} #{Faker::Number.between(from: 1, to: 9999)}"
    end
    short_title do
      "#{Faker::Book.title.gsub("&", "and")} #{Faker::Number.between(from: 1, to: 9999)}"
    end
    locale { "en" }

    transient do
      tag_count { 3 }
    end

    trait :term_independent do
      term_independent { true }
    end

    trait :with_organizational_stuff do
      organizational { true }
      organizational_concept { Faker::ChuckNorris.fact }
    end

    trait :locale_de do
      locale { "de" }
    end

    trait :with_image do
      after(:build) do |c|
        c.image = File.open("#{SPEC_FILES}/image.png", "rb")
      end
    end

    trait :with_image_and_normalization do
      with_image

      after :build, &:image_derivatives!
    end

    # call it with build(:course, :with_tags, tag_count: n) if you want
    # n tags associated to the course
    # omitting tag_count yields default of 3 tags
    trait :with_tags do
      after(:build) do |course, evaluator|
        course.tags = FactoryBot.create_list(:tag, evaluator.tag_count)
      end
    end

    trait :with_division do
      transient do
        division_id { nil }
      end

      after(:build) do |course, evaluator|
        if evaluator.division_id
          FactoryBot.create(:division_course_join,
                            course: course, division_id: evaluator.division_id)
        else
          division = FactoryBot.create(:division)
          FactoryBot.create(:division_course_join, course: course, division: division)
        end
      end
    end

    trait :with_editor_by_id do
      transient do
        editor_id { nil }
      end

      after(:build) do |course, evaluator|
        course.editors << User.find(evaluator.editor_id)
      end
    end
  end
end
