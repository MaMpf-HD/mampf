module Registration
  class AvailableItemsService
    def initialize(campaign)
      @campaign = campaign
      @lecture = campaign.campaignable
    end

    def items
      return {} unless @lecture.is_a?(Lecture)

      existing_type = @campaign.registration_items.first&.registerable_type
      groups = {}

      if existing_type.nil? || existing_type == "Tutorial"
        tutorials = @lecture.tutorials.where.not(id: existing_ids("Tutorial"))
        groups[:tutorials] = tutorials if tutorials.any?
      end

      if existing_type.nil? || existing_type == "Talk"
        talks = @lecture.talks.where.not(id: existing_ids("Talk"))
        groups[:talks] = talks if talks.any?
      end

      if (existing_type.nil? || existing_type == "Lecture") &&
         existing_ids("Lecture").exclude?(@lecture.id)
        groups[:lecture] = [@lecture]
      end

      groups
    end

    private

      def existing_ids(type)
        @campaign.registration_items.where(registerable_type: type).pluck(:registerable_id)
      end
  end
end
