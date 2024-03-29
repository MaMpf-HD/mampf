FactoryBot.define do
  factory :submission_cleaner do
    transient do
      date { Time.zone.today }
    end

    initialize_with do
      new(date: date)
    end
  end
end
