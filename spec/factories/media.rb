require 'faker'

FactoryGirl.define do
  factory :medium do
    sort %w[KaviarMedium ErdbeereMedium SesamMedium ResteMedium].sample
    author { Faker::Name.name }
    title { Faker::Book.title + ' ' + Random.rand(1..9).to_s }
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
    width Random.rand(800..1_800)
    height Random.rand(500..1_300)
    embedded_width Random.rand(800..1_800)
    embedded_height Random.rand(500..1_300)
    length Random.rand(0..9).to_s + 'h' + Random.rand(0..5).to_s +
           Random.rand(0..9).to_s + 'm' + Random.rand(0..5).to_s +
           Random.rand(0..9).to_s + 's'
    video_size Random.rand(1..1000.0).round(2).to_s + ' MiB'
    pages Random.rand(1..100)
    manuscript_size Random.rand(1..1000.0).round(2).to_s + ' KiB'
    authoring_software 'Camtasia ' + [*8..9].sample.to_s
  end
end
