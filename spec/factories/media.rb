require 'faker'

FactoryBot.define do
  factory :medium, aliases: [:linked_medium] do
    sort %w[Kaviar Erdbeere Sesam Kiwi Reste].sample
    author { Faker::Name.name }
    title { Faker::Book.title + ' ' + Faker::Number.between(1, 999).to_s }
    association :teachable, factory: [:lesson, :with_tags]
    description { Faker::TwinPeaks.quote }
    video_stream_link do
      Faker::Internet.url +
        Faker::Lorem.word +
        '.html'
    end
    video_file_link do
      Faker::Internet.url +
        Faker::Lorem.word +
        '.mp4'
    end
    video_thumbnail_link do
      Faker::Internet.url +
        Faker::Lorem.word +
        '.png'
    end
    manuscript_link do
      Faker::Internet.url +
        Faker::Lorem.word +
        '.pdf'
    end
    external_reference_link do
      Faker::Internet.url +
        Faker::Lorem.word +
        '.html'
    end
    width Faker::Number.between(800, 1800)
    height Faker::Number.between(500, 1300)
    embedded_width Faker::Number.between(800, 1800)
    embedded_height Faker::Number.between(500, 1300)
    length Faker::Number.between(0, 9).to_s + 'h' + Faker::Number.between(0, 5).to_s +
           Faker::Number.between(0, 9).to_s + 'm' + Faker::Number.between(0, 5).to_s +
           Faker::Number.between(0, 9).to_s + 's'
    video_size Faker::Number.decimal(3,2).to_s + ' MiB'
    pages  Faker::Number.between(1, 100)
    manuscript_size Faker::Number.decimal(3,2).to_s + ' KiB'
    authoring_software 'Camtasia ' + [*8..9].sample.to_s
    trait :with_tags do
      after(:build) { |m| m.tags = FactoryBot.create_list(:tag,2) }
    end
    trait :with_linked_media do
      after(:build) { |m| m.linked_media = FactoryBot.create_list(:medium,2) }
    end
  end
end
