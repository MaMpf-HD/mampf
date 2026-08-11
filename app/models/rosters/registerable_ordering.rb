module Rosters
  # Provides a consistent way to order "registerable" entities (Tutorials, Cohorts, Talks)
  class RegisterableOrdering
    TYPE_ORDER = {
      "Tutorial" => 0,
      "Talk" => 0,
      "Cohort" => 1
    }.freeze

    def self.sort(registerables)
      registerables.sort_by { |r| sort_key_for(r) }
    end

    def self.sort_items(items)
      items.sort_by { |item| sort_key_for(item.registerable) }
    end

    def self.item_sort_key(item)
      sort_key_for(item.registerable)
    end

    def self.sort_key_for(registerable)
      type_rank = TYPE_ORDER.fetch(registerable.class.name, 99)

      cohort_rank = if registerable.is_a?(Cohort)
        registerable.propagate_to_lecture? ? 0 : 1
      else
        0
      end

      position_key = if registerable.is_a?(Talk)
        registerable.position || 0
      else
        Float::INFINITY
      end

      title_key = registerable.title.to_s.downcase

      [type_rank, cohort_rank, position_key, title_key]
    end

    private_class_method :sort_key_for
  end
end
