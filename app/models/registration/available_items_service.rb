module Registration
  # Identifies registerable items (Tutorials, Talks, or the Lecture itself)
  # from the parent lecture that are not yet part of the campaign and enforces
  # type homogeneity by restricting results to the type of existing items,
  # ensuring a campaign contains only one category of registerables.
  class AvailableItemsService
    def initialize(campaign)
      @campaign = campaign
      @lecture = campaign.campaignable
    end

    def items
      return {} unless @lecture.is_a?(Lecture)

      prepare_registered_data

      groups = {}
      add_tutorials(groups) if type_allowed?("Tutorial")
      add_talks(groups) if type_allowed?("Talk")
      add_lecture(groups) if type_allowed?("Lecture")
      groups
    end

    private

      def prepare_registered_data
        pairs = @campaign.registration_items.pluck(:registerable_type, :registerable_id)
        @existing_type = pairs.first&.first
        @registered_ids = pairs.group_by(&:first).transform_values { |list| list.map(&:last) }
      end

      def type_allowed?(type)
        @existing_type.nil? || @existing_type == type
      end

      def add_tutorials(groups)
        ids = @registered_ids["Tutorial"] || []
        tutorials = @lecture.tutorials.where.not(id: ids)
        groups[:tutorials] = tutorials if tutorials.any?
      end

      def add_talks(groups)
        ids = @registered_ids["Talk"] || []
        talks = @lecture.talks.where.not(id: ids)
        groups[:talks] = talks if talks.any?
      end

      def add_lecture(groups)
        ids = @registered_ids["Lecture"] || []
        groups[:lecture] = [@lecture] unless ids.include?(@lecture.id)
      end
  end
end
