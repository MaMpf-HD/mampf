FactoryBot.define do
  factory :lecture do
    association :course
    association :teacher, factory: :confirmed_user
    association :term

    content_mode { "video" }
    sort { "lecture" }

    transient do
      chapter_count { 3 }
    end

    trait :with_organizational_stuff do
      organizational { true }
      organizational_concept { Faker::ChuckNorris.fact }
    end

    trait :released_for_all do
      released { "all" }
    end

    trait :term_independent do
      association :course, :term_independent
      term { nil }
    end

    # the chapters are created and not built because otherwise the
    # after_save callbacks will fail
    trait :with_toc do
      after(:build) do |lecture, evaluator|
        lecture.chapters = create_list(:chapter, evaluator.chapter_count,
                                       :with_sections)
      end
    end

    # has one chapter with one section
    trait :with_sparse_toc do
      after(:build) do |lecture|
        lecture.chapters = create_list(:chapter, 1,
                                       :with_sections, section_count: 1)
      end
    end

    trait :is_seminar do
      sort { "seminar" }
    end

    trait :with_forum do
      after(:build) do |lecture|
        forum = Thredded::Messageboard.new(name: lecture.forum_title)
        forum.save
        lecture.update(forum_id: forum.id) if forum.valid?
      end
    end

    trait :with_title do
      transient do
        title { Faker::Book.title }
      end
      # also see https://github.com/thoughtbot/factory_bot/issues/1391
      course { association :course, title: title }
    end

    # NOTE: that you can give the chapter_count here as parameter as well
    factory :lecture_with_toc, traits: [:with_toc]

    factory :lecture_with_sparse_toc, traits: [:with_sparse_toc]

    factory :seminar, traits: [:is_seminar]
  end
end
