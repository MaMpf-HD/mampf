FactoryBot.define do
  factory :annotation do
    medium_id { |id| id }
    user_id { |id| id }

    transient do
      annotation_time do
        # Pick a random number such that the annotation is still within the length
        # of the sample video (which is around 42s seconds long)
        seconds = nil
        while seconds.nil? || seconds.to_f > 40.00
          seconds = Faker::Number.decimal(l_digits: 2, r_digits: 2)
        end
        seconds
      end
    end

    timestamp do
      build(:time_stamp, total_seconds: annotation_time)
    end

    color { Annotation.colors.values.sample }
    category { Annotation.categories.keys.sample }

    trait :with_text do
      comment { Faker::Lorem.sentence }
    end
  end
end
