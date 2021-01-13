# frozen_string_literal: true

FactoryBot.define do
  factory :teachable_parser do
    transient do
      all_teachables { nil }
      teachable_ids { ['Course-1', 'Lecture-2', 'Lecture-3'] }
      teachable_inheritance { [true, false].sample }
    end

    initialize_with do
      new({ all_teachables: all_teachables,
            teachable_ids: teachable_ids,
            teachable_inheritance: teachable_inheritance })
    end
  end
end
