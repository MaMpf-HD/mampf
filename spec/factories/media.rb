FactoryGirl.define do
  factory :medium do
    author { Faker::Name.name }
    title { Faker::Book.title }
    video_stream_link { Faker::Internet.url + Faker::Lorem.word + '.html' }
    video_file_link { Faker::Internet.url + Faker::Lorem.word + '.mp4' }
    video_thumbnail_link { Faker::Internet.url + Faker::Lorem.word + '.png' }
    manuscript_link { Faker::Internet.url + Faker::Lorem.word + '.pdf'}
    external_reference_link { Faker::Internet.url + Faker::Lorem.word + '.html' }
    width [*800..1800].sample
    height [*500..1300].sample
    embedded_width [*800..1800].sample
    embedded_height [*500..1300].sample
    length [*10..10000].sample
    video_size [*1..10737418240].sample
    pages [*1..100].sample
    manuscript_size [*1..104857600].sample
  end
end

# t.integer "width"
# t.integer "height"
# t.integer "embedded_width"
# t.integer "embedded_height"
# t.integer "length"
# t.integer "video_size", limit: 8
# t.integer "pages"
# t.integer "manuscript_size"
