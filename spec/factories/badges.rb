FactoryBot.define do
  factory :badge do
    title { "Invalid Badge" }
    description { "I am an invalid badge and should not exist" }
    icon_key { "invalid_icon" }

    trait :comments do
      title { "Kommentare" }
      description { "Verfasse 10 Kommentare" }
      icon_key { "comments_icon" }
    end

    trait :annotations do
      title { "Annotationen" }
      description { "Verfasse 10, für Dozierende sichtbare, Annotationen" }
      icon_key { "annotations_icon" }
    end

    trait :threads do
      title { "Threads" }
      description { "Öffne 10 neue Topics in Vorlesungsforen" }
      icon_key { "threads_icon" }
    end
  end
end
