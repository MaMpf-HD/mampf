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
        return false if @campaign.planning_only? && type != "Lecture"

        @existing_type.nil? || @existing_type == type
      end

      def add_tutorials(groups)
        used_ids = Registration::Item.where(registerable_type: "Tutorial").pluck(:registerable_id)
        tutorials = @lecture.tutorials.where(managed_by_campaign: true).where.not(id: used_ids)
        groups[:tutorials] = tutorials if tutorials.any?
      end

      def add_talks(groups)
        used_ids = Registration::Item.where(registerable_type: "Talk").pluck(:registerable_id)
        talks = @lecture.talks.where(managed_by_campaign: true).where.not(id: used_ids)
        groups[:talks] = talks if talks.any?
      end

      def add_lecture(groups)
        ids = @registered_ids["Lecture"] || []
        return if ids.include?(@lecture.id)

        unless @campaign.planning_only?
          is_used_in_real = Registration::Item.joins(:registration_campaign)
                                              .where(registerable_type: "Lecture",
                                                     registerable_id: @lecture.id)
                                              .exists?(registration_campaigns:
                                              { planning_only: false })
          return if is_used_in_real
        end

        groups[:lecture] = [@lecture]
      end
  end
end
